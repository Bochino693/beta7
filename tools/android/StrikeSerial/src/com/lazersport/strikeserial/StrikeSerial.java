package com.lazersport.strikeserial;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.hardware.usb.UsbConstants;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbEndpoint;
import android.hardware.usb.UsbInterface;
import android.hardware.usb.UsbManager;
import android.os.Build;
import android.os.SystemClock;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import java.io.IOException;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * ARDUINO PELO USB DA TV BOX (Olho no Lance; o mesmo plugin do Strike Kids): os 5 sensores da pista, o botão
 * de configuração e a trava (porta) passam pelo Arduino, ligado no USB.
 *
 * Driver próprio, sem biblioteca de fora (nada de JitPack): o APK pronto e
 * o do GERAR_APK levam tudo. Chips que ele conhece:
 *   - CDC/ACM: Arduino Uno, Mega, Leonardo, Micro, Nano Every originais e
 *     os chips CH9102 (qualquer aparelho de classe CDC);
 *   - CH340 / CH341: Arduino Nano e Uno "clone" (o mais comum);
 *   - FTDI FT232R / FT231X: Nano original antigo;
 *   - CP2102 / CP2104 (Silicon Labs).
 * Sempre 8N1, com DTR e RTS ligados (no Uno/Nano isso reinicia o Arduino,
 * que responde OLA de novo — o jogo usa isso para saber que é ele).
 *
 * Permissão USB: pedir_permissao() abre a janela do Android; a atividade
 * de encaixe (StrikeArduinoAtivo) com o filtro dos Arduinos faz o Android
 * oferecer "Usar por padrão" — marcada uma vez, fica guardada.
 *
 * GDScript:  var s = Engine.get_singleton("StrikeSerial")
 *   s.listar()             "nome|VID:PID|tipo|permissão(1/0)|produto" por linha
 *   s.pedir_permissao(n)   janela do Android (uma por vez)
 *   s.abrir(n, 9600)       abre em segundo plano; s.estado() diz como foi
 *   s.estado()             fechada | abrindo | aberta | erro
 *   s.ler()                linhas completas que chegaram (separadas por \n)
 *   s.escrever("PING")     manda uma linha (o \n vai junto)
 *   s.fechar(); s.erro(); s.relatorio()
 * Tudo também vai para o logcat com a etiqueta "StrikeSerial".
 */
public class StrikeSerial extends GodotPlugin {

	private static final String TAG = "StrikeSerial";
	private static final String ACAO_USB = "com.lazersport.strikeserial.PERMISSAO_USB";
	private static final int FLAG_IMMUTABLE = 0x04000000; // PendingIntent.FLAG_IMMUTABLE (Android 6+)
	private static final int TEMPO_LEITURA_MS = 200;
	private static final Charset ASCII = Charset.forName("US-ASCII");

	private final ExecutorService trabalho = Executors.newSingleThreadExecutor();
	private final ExecutorService escritor = Executors.newSingleThreadExecutor();
	private final SerialUtil.Linhas linhas = new SerialUtil.Linhas(200);
	private final StringBuilder diario = new StringBuilder();
	private final Set<Integer> pedidos = new HashSet<Integer>();
	private UsbManager usb;

	private volatile String lista = "";
	private volatile long listadaEm = 0;
	private volatile boolean listando = false;
	private volatile String estado = "fechada";
	private volatile String erro = "";
	private volatile Porta porta;
	private volatile int geracao = 0;
	private volatile Thread leitor;
	private volatile long permissaoDesde = 0;
	private volatile long bytesRx = 0;
	private volatile long bytesTx = 0;
	private volatile int baudAtual = 0;

	public StrikeSerial(Godot godot) {
		super(godot);
	}

	@Override
	public String getPluginName() {
		return "StrikeSerial";
	}

	private void anotar(String s) {
		try {
			Log.i(TAG, s);
		} catch (Throwable ignored) {
		}
		synchronized (diario) {
			if (diario.length() > 4000) {
				diario.delete(0, diario.length() - 2000);
			}
			diario.append(SystemClock.elapsedRealtime() / 1000).append("s ").append(s).append('\n');
		}
	}

	private UsbManager usb() {
		if (usb == null) {
			Activity a = getActivity();
			if (a != null) {
				usb = (UsbManager) a.getSystemService(Context.USB_SERVICE);
			}
		}
		return usb;
	}

	// ------------------------------------------------------------ listar
	/** Que chip é este aparelho? null = não é uma porta serial conhecida. */
	static String tipoDe(UsbDevice d) {
		int vid = d.getVendorId();
		int pid = d.getProductId();
		if (vid == 0x1A86 && (pid == 0x7523 || pid == 0x5523 || pid == 0x7522)) {
			return "ch34x";
		}
		if (vid == 0x0403) {
			return "ftdi";
		}
		if (vid == 0x10C4 && (pid == 0xEA60 || pid == 0xEA70 || pid == 0xEA71 || pid == 0xEA80)) {
			return "cp210x";
		}
		for (int i = 0; i < d.getInterfaceCount(); i++) {
			int c = d.getInterface(i).getInterfaceClass();
			if (c == UsbConstants.USB_CLASS_CDC_DATA || c == UsbConstants.USB_CLASS_COMM) {
				return "cdc";
			}
		}
		return null;
	}

	private String listarAgora() {
		UsbManager m = usb();
		if (m == null) {
			return "";
		}
		StringBuilder sb = new StringBuilder();
		HashMap<String, UsbDevice> todos = m.getDeviceList();
		for (UsbDevice d : todos.values()) {
			String tipo = tipoDe(d);
			if (tipo == null) {
				continue;
			}
			String produto = "";
			try {
				if (Build.VERSION.SDK_INT >= 21 && d.getProductName() != null) {
					produto = d.getProductName().replace('|', '/').replace('\n', ' ');
				}
			} catch (Throwable ignored) {
				// sem permissão alguns Android não deixam ler o nome
			}
			sb.append(d.getDeviceName()).append('|')
					.append(String.format("%04X:%04X", d.getVendorId(), d.getProductId())).append('|')
					.append(tipo).append('|')
					.append(m.hasPermission(d) ? "1" : "0").append('|')
					.append(produto).append('\n');
		}
		return sb.toString();
	}

	/**
	 * As portas seriais no USB. A lista vem pronta (é refeita em segundo
	 * plano, no máximo a cada 1 s): o jogo nunca espera o USB.
	 */
	@UsedByGodot
	public String listar() {
		long agora = SystemClock.elapsedRealtime();
		if (!listando && agora - listadaEm > 1000) {
			listando = true;
			trabalho.execute(new Runnable() {
				@Override
				public void run() {
					try {
						lista = listarAgora();
					} catch (Throwable t) {
						anotar("erro ao listar o usb: " + t.getMessage());
					} finally {
						listadaEm = SystemClock.elapsedRealtime();
						listando = false;
					}
				}
			});
		}
		return lista;
	}

	// ------------------------------------------------------------ permissão
	/** A janela "Permitir que o Olho no Lance acesse o dispositivo USB?" está aberta? */
	@UsedByGodot
	public boolean permissao_pendente() {
		long desde = permissaoDesde;
		return desde != 0 && SystemClock.elapsedRealtime() - desde < 30000;
	}

	@UsedByGodot
	public String pedir_permissao(String nome) {
		final Activity a = getActivity();
		if (a == null) {
			return "tela ainda nao disponivel";
		}
		UsbManager m = usb();
		final UsbDevice d = m != null ? m.getDeviceList().get(nome) : null;
		if (d == null) {
			return "aparelho nao encontrado";
		}
		if (m.hasPermission(d)) {
			return "ok";
		}
		if (permissao_pendente()) {
			return "janela de permissao aberta";
		}
		permissaoDesde = SystemClock.elapsedRealtime();
		synchronized (pedidos) {
			pedidos.add(d.getDeviceId());
		}
		anotar("pedindo permissao usb de " + d.getDeviceName());
		a.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				try {
					Intent it = new Intent(ACAO_USB);
					it.setPackage(a.getPackageName());
					// (o jogo não lê a resposta deste aviso - ele olha hasPermission -,
					// então o aviso pode ser "imutável": o Android 14+ recusa criar um
					// aviso mutável sem destino explícito e a janela nem abria)
					int flags = PendingIntent.FLAG_UPDATE_CURRENT | (Build.VERSION.SDK_INT >= 23 ? FLAG_IMMUTABLE : 0);
					PendingIntent pi = PendingIntent.getBroadcast(a, 7400 + d.getDeviceId(), it, flags);
					usb().requestPermission(d, pi);
				} catch (Throwable t) {
					permissaoDesde = 0;
					anotar("pedido de permissao falhou: " + t.getMessage());
				}
			}
		});
		return "pedido";
	}

	// ------------------------------------------------------------ abrir
	@UsedByGodot
	public String estado() {
		return estado;
	}

	@UsedByGodot
	public String erro() {
		return erro;
	}

	/** Abre a porta em segundo plano (o jogo acompanha por estado()). */
	@UsedByGodot
	public void abrir(final String nome, final int baud) {
		fechar();
		final int g = geracao;
		estado = "abrindo";
		erro = "";
		trabalho.execute(new Runnable() {
			@Override
			public void run() {
				abrirAgora(nome, baud, g);
			}
		});
	}

	private void falhar(int g, String motivo) {
		anotar(motivo);
		if (g == geracao) {
			erro = motivo;
			estado = "erro";
		}
	}

	private void abrirAgora(String nome, int baud, int g) {
		// a leitura da porta anterior termina antes (o USB não abre duas vezes)
		Thread antigo = leitor;
		if (antigo != null) {
			try {
				antigo.join(1500);
			} catch (InterruptedException ignored) {
			}
		}
		if (g != geracao) {
			return;
		}
		UsbManager m = usb();
		UsbDevice d = m != null ? m.getDeviceList().get(nome) : null;
		if (d == null) {
			falhar(g, "o aparelho saiu do USB");
			return;
		}
		if (!m.hasPermission(d)) {
			falhar(g, "sem permissao USB (aceite a janela do Android)");
			return;
		}
		synchronized (pedidos) {
			pedidos.remove(d.getDeviceId());
		}
		permissaoDesde = 0;
		String tipo = tipoDe(d);
		UsbDeviceConnection c = m.openDevice(d);
		if (c == null) {
			falhar(g, "o Android recusou abrir o USB");
			return;
		}
		Porta p;
		if ("ch34x".equals(tipo)) {
			p = new Ch34x(d, c);
		} else if ("ftdi".equals(tipo)) {
			p = new Ftdi(d, c);
		} else if ("cp210x".equals(tipo)) {
			p = new Cp210x(d, c);
		} else {
			p = new Cdc(d, c);
		}
		try {
			p.abrir(baud);
		} catch (Throwable t) {
			p.fechar();
			falhar(g, "falha ao abrir " + p.tipo() + ": " + t.getMessage());
			return;
		}
		if (g != geracao) {
			p.fechar();
			return;
		}
		linhas.limpar();
		porta = p;
		baudAtual = baud;
		estado = "aberta";
		erro = "";
		anotar("aberta: " + p.tipo() + " " + String.format("%04X:%04X", d.getVendorId(), d.getProductId()) + " a " + baud);
		final Porta pp = p;
		final int gg = g;
		Thread t = new Thread(new Runnable() {
			@Override
			public void run() {
				ler(pp, gg);
			}
		}, "StrikeSerial-leitura");
		t.setDaemon(true);
		leitor = t;
		t.start();
	}

	/** Lê sem parar (numa linha de execução própria) até fechar ou sair do USB. */
	private void ler(Porta p, int g) {
		byte[] buf = new byte[p.tamanhoLeitura()];
		int erradas = 0;
		long conferiu = SystemClock.uptimeMillis();
		try {
			while (g == geracao) {
				long t0 = SystemClock.uptimeMillis();
				int n = p.ler(buf, TEMPO_LEITURA_MS);
				long agora = SystemClock.uptimeMillis();
				if (n > 0) {
					bytesRx += n;
					linhas.receber(buf, 0, n);
					erradas = 0;
				} else if (n < 0 && agora - t0 < TEMPO_LEITURA_MS / 4) {
					// erro na hora (não é o tempo-limite da leitura)
					if (++erradas > 25) {
						falhar(g, "o USB parou de responder");
						break;
					}
					SystemClock.sleep(10);
				}
				if (agora - conferiu > 1000) {
					conferiu = agora;
					UsbManager m = usb();
					if (m != null && !m.getDeviceList().containsKey(p.dispositivo.getDeviceName())) {
						falhar(g, "o Arduino saiu do USB");
						break;
					}
				}
			}
		} catch (Throwable t) {
			falhar(g, "erro na leitura: " + t.getMessage());
		} finally {
			p.fechar();
			if (porta == p) {
				porta = null;
			}
		}
	}

	@UsedByGodot
	public String ler() {
		return linhas.tirar();
	}

	@UsedByGodot
	public boolean escrever(String linha) {
		final Porta p = porta;
		if (p == null || !"aberta".equals(estado)) {
			return false;
		}
		final byte[] dados = (linha.trim() + "\n").getBytes(ASCII);
		escritor.execute(new Runnable() {
			@Override
			public void run() {
				int n = p.escrever(dados, 500);
				if (n < 0) {
					anotar("falha ao escrever no usb");
				} else {
					bytesTx += n;
				}
			}
		});
		return true;
	}

	@UsedByGodot
	public void fechar() {
		geracao++;
		Porta p = porta;
		porta = null;
		estado = "fechada";
		linhas.limpar();
		if (p != null && leitor == null) {
			p.fechar();
		}
	}

	@Override
	public void onMainDestroy() {
		fechar();
	}

	// ------------------------------------------------------------ abrir ao ligar
	// InicioDaTv: o jogo se prepara sozinho (root / adb da TV), a tela inicial
	// do jogo, o aviso de "ligou" (StrikeLigou) e o guarda (StrikeSempre).
	private static boolean inicioPedido = false;

	@Override
	public View onMainCreate(Activity activity) {
		try {
			if (Build.VERSION.SDK_INT >= 27) {
				activity.setTurnScreenOn(true);
				activity.setShowWhenLocked(true);
			} else {
				activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
						| WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED | WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD);
			}
			activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
		} catch (Throwable t) {
			anotar("inicio: acender a tela: " + t);
		}
		try {
			// a TV voltando da espera (ligada pelo controle) reinicia o jogo
			InicioDaTv.ouvirTela(activity);
			// o guarda: outra tela por cima ou a TV ligada pelo controle - o jogo volta
			StrikeSempre.comecar(activity.getApplicationContext());
		} catch (Throwable t) {
			anotar("inicio: " + t);
		}
		// O JOGO SE PREPARA SOZINHO, em silêncio, logo ao abrir: pelo root ou
		// pelo adb da própria TV. Nada aparece na tela (a não ser o "Permitir
		// depuração?" de uma TV com a depuração ligada e com senha).
		final Context app = activity.getApplicationContext();
		new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					if (InicioDaTv.estado(app).equals("jogo") && InicioDaTv.podeAbrirDeFundo(app)) {
						return;
					}
					if (!InicioDaTv.telaDoJogoLigada(app)) {
						return;
					}
					InicioDaTv.pausarGuarda(app, 2 * 60000L);
					anotar("inicio: sozinho: " + InicioDaTv.prepararSozinho(app));
				} catch (Throwable t) {
					anotar("inicio: sozinho: " + t);
				} finally {
					preparou = true;
				}
			}
		}, "GolFlashInicio").start();
		return null;
	}

	private static volatile boolean preparou = false;

	@Override
	public void onMainResume() {
		InicioDaTv.naFrente = true;
		Activity a = getActivity();
		if (a != null) {
			StrikeSempre.comecar(a.getApplicationContext());
		}
	}

	@Override
	public void onMainPause() {
		InicioDaTv.naFrente = false;
	}

	/**
	 * SÓ SE A TV BOX NÃO DEIXOU O JOGO SE PREPARAR SOZINHO (sem root e sem
	 * adb): o jogo chama com o menu parado há um tempo, uma vez por abertura.
	 * Android 10+: abre "Sobrepor a outros apps"; Android 9 ou mais antigo: a
	 * escolha da tela inicial. Devolve "pedindo", "ja" (não falta nada),
	 * "espere" (ainda se preparando) ou "".
	 */
	@UsedByGodot
	public String preparar_inicio() {
		final Activity a = getActivity();
		if (a == null || inicioPedido) {
			return "";
		}
		if (!preparou) {
			return "espere";
		}
		inicioPedido = true;
		try {
			String estado = InicioDaTv.estado(a);
			if (!InicioDaTv.telaDoJogoLigada(a) || (estado.equals("jogo") && InicioDaTv.podeAbrirDeFundo(a))) {
				return "ja";
			}
			InicioDaTv.pausarGuarda(a, 3 * 60000L);
			if (Build.VERSION.SDK_INT >= 29) {
				if (InicioDaTv.podeAbrirDeFundo(a)) {
					return "ja";
				}
				anotar("inicio: pedindo 'Sobrepor a outros apps': " + InicioDaTv.pedirSobrepor(a));
			} else {
				if (estado.equals("jogo")) {
					return "ja";
				}
				anotar("inicio: a TV ainda não abre o jogo (" + estado + "): " + InicioDaTv.escolher(a, true));
			}
			return "pedindo";
		} catch (Throwable t) {
			anotar("inicio: " + t);
			return "";
		}
	}

	/** Tenta de novo se preparar sozinho (Central da Máquina): o resultado sai no inicio_relatorio(). */
	@UsedByGodot
	public void preparar_sozinho() {
		final Activity a = getActivity();
		if (a == null) {
			return;
		}
		final Context app = a.getApplicationContext();
		new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					InicioDaTv.pausarGuarda(app, 2 * 60000L);
					anotar("inicio: sozinho: " + InicioDaTv.prepararSozinho(app));
				} catch (Throwable t) {
					anotar("inicio: sozinho: " + t);
				}
			}
		}, "GolFlashInicio").start();
	}

	/** O estado do "abrir ao ligar" (linhas nome=valor) para a Central da Máquina. */
	@UsedByGodot
	public String inicio_relatorio() {
		Activity a = getActivity();
		try {
			return a == null ? "" : InicioDaTv.relatorio(a);
		} catch (Throwable t) {
			return "";
		}
	}

	/** Abre a escolha da tela inicial do Android: "ja", "papel", "ajustes", "escolha", "app", "config" ou "". */
	@UsedByGodot
	public String escolher_tela_inicial() {
		Activity a = getActivity();
		if (a == null) {
			return "";
		}
		try {
			InicioDaTv.pausarGuarda(a, 3 * 60000L);
			return InicioDaTv.escolher(a, false);
		} catch (Throwable t) {
			anotar("tela inicial: " + t);
			return "";
		}
	}

	/** Só as janelas de ESCOLHA da tela inicial (nunca páginas de ajustes soltas): "ja", "papel", "ajustes", "escolha" ou "". */
	@UsedByGodot
	public String pedir_tela_inicial() {
		Activity a = getActivity();
		if (a == null) {
			return "";
		}
		try {
			InicioDaTv.pausarGuarda(a, 3 * 60000L);
			return InicioDaTv.escolher(a, true);
		} catch (Throwable t) {
			anotar("tela inicial: " + t);
			return "";
		}
	}

	/** Abre a tela "Sobrepor a outros apps" (Android 10+): true se abriu. */
	@UsedByGodot
	public boolean pedir_sobrepor() {
		Activity a = getActivity();
		if (a == null) {
			return false;
		}
		try {
			InicioDaTv.pausarGuarda(a, 3 * 60000L);
			return InicioDaTv.pedirSobrepor(a);
		} catch (Throwable t) {
			anotar("sobrepor: " + t);
			return false;
		}
	}

	/** Abre a tela inicial da própria TV (o guarda espera 15 min): o nome dela, "config" ou "". */
	@UsedByGodot
	public String sair_para_tv() {
		Activity a = getActivity();
		if (a == null) {
			return "";
		}
		try {
			return InicioDaTv.sairParaTv(a);
		} catch (Throwable t) {
			anotar("sair para a TV: " + t);
			return "";
		}
	}

	@Override
	public void onMainActivityResult(int pedido, int resultado, Intent dados) {
		Activity a = getActivity();
		if (pedido == PendriveDaTv.PEDIDO_PASTA && a != null) {
			try {
				PendriveDaTv.depoisDeEscolher(a, resultado, dados);
			} catch (Throwable t) {
				anotar("pendrive: " + t);
			}
			return;
		}
		if (pedido == InicioDaTv.PEDIDO_PAPEL && a != null) {
			try {
				InicioDaTv.depoisDoPapel(a, resultado);
			} catch (Throwable t) {
				anotar("tela inicial: " + t);
			}
		}
	}

	// ------------------------------------------------------- pontos da tela
	private boolean pontosMexidos = false;

	private static SurfaceView acharTela(View v) {
		if (v instanceof SurfaceView) {
			return (SurfaceView) v;
		}
		if (v instanceof ViewGroup) {
			ViewGroup g = (ViewGroup) v;
			for (int i = 0; i < g.getChildCount(); i++) {
				SurfaceView s = acharTela(g.getChildAt(i));
				if (s != null) {
					return s;
				}
			}
		}
		return null;
	}

	/**
	 * QUANTOS PONTOS O JOGO PINTA (a nitidez), sem mudar o desenho dele: a
	 * imagem é feita com "altura" linhas e o próprio Android estica até o
	 * tamanho da TV (de graça, pelo hardware). altura 0, ou igual / maior que
	 * a da TV = os pontos da TV. Devolve os pontos da TV ("1920x1080").
	 */
	@UsedByGodot
	public String pontos_da_tela(final int altura) {
		final Activity a = getActivity();
		if (a == null) {
			return "";
		}
		try {
			DisplayMetrics m = new DisplayMetrics();
			a.getWindowManager().getDefaultDisplay().getRealMetrics(m);
			final int tw = Math.max(m.widthPixels, m.heightPixels);
			final int th = Math.min(m.widthPixels, m.heightPixels);
			final boolean inteira = altura <= 0 || altura >= th;
			if (inteira && !pontosMexidos) {
				return tw + "x" + th;   // nunca mexeu: fica como o Android entrega
			}
			pontosMexidos = true;
			a.runOnUiThread(new Runnable() {
				@Override
				public void run() {
					try {
						SurfaceView v = acharTela(a.getWindow().getDecorView());
						if (v == null) {
							return;
						}
						if (inteira) {
							v.getHolder().setSizeFromLayout();
						} else {
							int w = Math.round(altura * (float) tw / (float) th);
							w -= w % 2;
							v.getHolder().setFixedSize(w, altura);
						}
					} catch (Throwable t) {
						anotar("pontos da tela: " + t);
					}
				}
			});
			return tw + "x" + th;
		} catch (Throwable t) {
			anotar("pontos da tela: " + t);
			return "";
		}
	}

	// ------------------------------------------------------------ pendrive
	// PendriveDaTv: os cadastros do MODO FEIRA vão para o pendrive.
	/** A pasta OlhoNoLance_Leads de um pendrive onde dá para escrever ("" = nenhuma). */
	@UsedByGodot
	public String pen_pasta() {
		Activity a = getActivity();
		return a == null ? "" : PendriveDaTv.pastaDireta(a);
	}

	@UsedByGodot
	public String arq_ler(String caminho) {
		return PendriveDaTv.lerArquivo(caminho);
	}

	@UsedByGodot
	public boolean arq_gravar(String caminho, String texto) {
		return PendriveDaTv.gravarArquivo(caminho, texto);
	}

	/** Abre o seletor de pastas do Android (o operador escolhe o pendrive uma vez). */
	@UsedByGodot
	public boolean pen_escolher() {
		Activity a = getActivity();
		if (a == null) {
			return false;
		}
		InicioDaTv.pausarGuarda(a, 3 * 60000L);
		return PendriveDaTv.escolher(a);
	}

	/** O nome da pasta escolhida ("" = nenhuma, ou o pendrive dela não está espetado). */
	@UsedByGodot
	public String pen_nome() {
		Activity a = getActivity();
		return a == null ? "" : PendriveDaTv.nome(a);
	}

	@UsedByGodot
	public String pen_ler(String rel) {
		Activity a = getActivity();
		return a == null ? "" : PendriveDaTv.ler(a, rel);
	}

	@UsedByGodot
	public boolean pen_gravar(String rel, String texto) {
		Activity a = getActivity();
		return a != null && PendriveDaTv.gravar(a, rel, texto);
	}

	/** Antes de tirar o pendrive: o Android grava de verdade o que ainda estava na memória. */
	@UsedByGodot
	public void pen_sincronizar() {
		PendriveDaTv.sincronizar();
	}

	// ------------------------------------------------------------ relatório
	/** O que o Android enxerga no USB e o que esta ponte fez (menu do operador). */
	@UsedByGodot
	public String relatorio() {
		StringBuilder sb = new StringBuilder();
		sb.append("Android ").append(Build.VERSION.RELEASE).append(" (API ").append(Build.VERSION.SDK_INT).append(")\n");
		UsbManager m = usb();
		if (m == null) {
			sb.append("USB: indisponivel\n");
		} else {
			HashMap<String, UsbDevice> todos = m.getDeviceList();
			sb.append("Aparelhos USB: ").append(todos.size()).append('\n');
			for (UsbDevice d : todos.values()) {
				StringBuilder classes = new StringBuilder();
				for (int i = 0; i < d.getInterfaceCount(); i++) {
					if (i > 0) {
						classes.append(',');
					}
					classes.append(d.getInterface(i).getInterfaceClass());
				}
				String tipo = tipoDe(d);
				sb.append(String.format("  %04X:%04X classe %s", d.getVendorId(), d.getProductId(), classes))
						.append(tipo != null ? " SERIAL(" + tipo + ")" : "")
						.append(m.hasPermission(d) ? " permitido" : " sem permissao").append('\n');
			}
		}
		Porta p = porta;
		sb.append("Porta: ").append(estado);
		if (p != null) {
			sb.append(" ").append(p.tipo()).append(" a ").append(baudAtual);
		}
		sb.append(" | recebidos ").append(bytesRx).append(" bytes, enviados ").append(bytesTx).append('\n');
		if (erro.length() > 0) {
			sb.append("Erro: ").append(erro).append('\n');
		}
		synchronized (diario) {
			sb.append(diario);
		}
		return sb.toString();
	}

	// ------------------------------------------------------------ chips
	private static UsbEndpoint[] pontas(UsbInterface it) {
		UsbEndpoint entrada = null;
		UsbEndpoint saida = null;
		for (int i = 0; i < it.getEndpointCount(); i++) {
			UsbEndpoint e = it.getEndpoint(i);
			if (e.getType() != UsbConstants.USB_ENDPOINT_XFER_BULK) {
				continue;
			}
			if (e.getDirection() == UsbConstants.USB_DIR_IN) {
				if (entrada == null) {
					entrada = e;
				}
			} else if (saida == null) {
				saida = e;
			}
		}
		return new UsbEndpoint[] { entrada, saida };
	}

	/** Uma porta serial aberta num chip. */
	abstract static class Porta {
		final UsbDevice dispositivo;
		final UsbDeviceConnection con;
		final List<UsbInterface> reservadas = new ArrayList<UsbInterface>();
		UsbEndpoint entrada;
		UsbEndpoint saida;

		Porta(UsbDevice d, UsbDeviceConnection c) {
			dispositivo = d;
			con = c;
		}

		abstract String tipo();

		abstract void abrir(int baud) throws IOException;

		void reservar(UsbInterface it) throws IOException {
			if (!con.claimInterface(it, true)) {
				throw new IOException("nao consegui reservar a interface " + it.getId());
			}
			reservadas.add(it);
		}

		void pontasDe(UsbInterface it) throws IOException {
			UsbEndpoint[] p = pontas(it);
			entrada = p[0];
			saida = p[1];
			if (entrada == null || saida == null) {
				throw new IOException("sem os canais de dados (bulk)");
			}
		}

		int tamanhoLeitura() {
			return Math.max(64, entrada.getMaxPacketSize());
		}

		int ler(byte[] buf, int tempoMs) {
			return con.bulkTransfer(entrada, buf, buf.length, tempoMs);
		}

		int escrever(byte[] dados, int tempoMs) {
			return con.bulkTransfer(saida, dados, dados.length, tempoMs);
		}

		int controle(int tipo, int pedido, int valor, int indice, byte[] dados) {
			return con.controlTransfer(tipo, pedido, valor, indice, dados, dados == null ? 0 : dados.length, 1000);
		}

		void exigir(int tipo, int pedido, int valor, int indice, byte[] dados) throws IOException {
			if (controle(tipo, pedido, valor, indice, dados) < 0) {
				throw new IOException(String.format("pedido 0x%02X falhou", pedido));
			}
		}

		void fechar() {
			for (UsbInterface it : reservadas) {
				try {
					con.releaseInterface(it);
				} catch (Throwable ignored) {
				}
			}
			reservadas.clear();
			try {
				con.close();
			} catch (Throwable ignored) {
			}
		}
	}

	/** CDC/ACM: Arduinos originais (Uno, Mega, Leonardo...) e CH9102. */
	static final class Cdc extends Porta {
		Cdc(UsbDevice d, UsbDeviceConnection c) {
			super(d, c);
		}

		@Override
		String tipo() {
			return "cdc";
		}

		@Override
		void abrir(int baud) throws IOException {
			UsbInterface ctrl = null;
			UsbInterface dados = null;
			for (int i = 0; i < dispositivo.getInterfaceCount(); i++) {
				UsbInterface it = dispositivo.getInterface(i);
				if (it.getInterfaceClass() == UsbConstants.USB_CLASS_COMM && ctrl == null) {
					ctrl = it;
				} else if (it.getInterfaceClass() == UsbConstants.USB_CLASS_CDC_DATA && dados == null) {
					dados = it;
				}
			}
			if (dados == null) {
				// alguns aparelhos põem tudo numa interface só
				for (int i = 0; i < dispositivo.getInterfaceCount() && dados == null; i++) {
					UsbEndpoint[] p = pontas(dispositivo.getInterface(i));
					if (p[0] != null && p[1] != null) {
						dados = dispositivo.getInterface(i);
					}
				}
			}
			if (dados == null) {
				throw new IOException("sem interface de dados CDC");
			}
			if (ctrl != null) {
				try {
					reservar(ctrl);
				} catch (IOException ignored) {
					// os pedidos de classe funcionam mesmo sem reservar
				}
			}
			reservar(dados);
			pontasDe(dados);
			int indice = ctrl != null ? ctrl.getId() : 0;
			// SET_LINE_CODING (8N1) e SET_CONTROL_LINE_STATE (DTR + RTS: o
			// Leonardo só manda dados com o DTR ligado; o Uno reinicia)
			controle(0x21, 0x20, 0, indice, SerialUtil.cdcLinha(baud));
			controle(0x21, 0x22, 0x0003, indice, null);
		}
	}

	/** CH340 / CH341: os Arduinos "clone" (Nano, Uno). Como o ch341.c do Linux. */
	static final class Ch34x extends Porta {
		Ch34x(UsbDevice d, UsbDeviceConnection c) {
			super(d, c);
		}

		@Override
		String tipo() {
			return "ch340";
		}

		@Override
		void abrir(int baud) throws IOException {
			UsbInterface it = dispositivo.getInterface(0);
			reservar(it);
			pontasDe(it);
			byte[] versao = new byte[2];
			int lido = controle(0xC0, 0x5F, 0, 0, versao);   // versão do chip
			int v = lido >= 1 ? (versao[0] & 0xFF) : 0x30;
			exigir(0x40, 0xA1, 0, 0, null);                   // inicia a serial
			exigir(0x40, 0x9A, 0x1312, SerialUtil.ch34xDivisor(baud), null);
			if (v >= 0x30) {
				exigir(0x40, 0x9A, 0x2518, 0x00C3, null);     // liga RX/TX, 8 bits
			}
			exigir(0x40, 0xA4, (~0x60) & 0xFFFF, 0, null);    // DTR + RTS ligados
		}
	}

	/** FTDI FT232R / FT231X. Cada pacote lido traz 2 bytes de estado na frente. */
	static final class Ftdi extends Porta {
		private int pacote = 64;

		Ftdi(UsbDevice d, UsbDeviceConnection c) {
			super(d, c);
		}

		@Override
		String tipo() {
			return "ftdi";
		}

		@Override
		void abrir(int baud) throws IOException {
			UsbInterface it = dispositivo.getInterface(0);
			reservar(it);
			pontasDe(it);
			pacote = Math.max(8, entrada.getMaxPacketSize());
			exigir(0x40, 0x00, 0x0000, 1, null);              // reset
			int[] div = SerialUtil.ftdiDivisor(baud);
			exigir(0x40, 0x03, div[0], div[1], null);         // baud
			exigir(0x40, 0x04, 0x0008, 1, null);              // 8N1
			controle(0x40, 0x02, 0x0000, 1, null);            // sem controle de fluxo
			controle(0x40, 0x01, 0x0303, 1, null);            // DTR + RTS ligados
			controle(0x40, 0x09, 8, 1, null);                 // entrega a cada 8 ms
		}

		@Override
		int tamanhoLeitura() {
			return pacote;
		}

		@Override
		int ler(byte[] buf, int tempoMs) {
			int n = super.ler(buf, tempoMs);
			if (n <= 0) {
				return n;
			}
			return SerialUtil.ftdiTirarEstado(buf, n, pacote);
		}
	}

	/** Silicon Labs CP2102 / CP2104. */
	static final class Cp210x extends Porta {
		Cp210x(UsbDevice d, UsbDeviceConnection c) {
			super(d, c);
		}

		@Override
		String tipo() {
			return "cp210x";
		}

		@Override
		void abrir(int baud) throws IOException {
			UsbInterface it = dispositivo.getInterface(0);
			reservar(it);
			pontasDe(it);
			int indice = it.getId();
			exigir(0x41, 0x00, 0x0001, indice, null);         // liga a UART
			byte[] b = new byte[] { (byte) baud, (byte) (baud >> 8), (byte) (baud >> 16), (byte) (baud >> 24) };
			exigir(0x41, 0x1E, 0, indice, b);                 // baud
			exigir(0x41, 0x03, 0x0800, indice, null);         // 8N1
			controle(0x41, 0x07, 0x0303, indice, null);       // DTR + RTS ligados
		}
	}
}
