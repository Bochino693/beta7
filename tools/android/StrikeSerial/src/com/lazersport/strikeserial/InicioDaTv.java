package com.lazersport.strikeserial;

import android.app.Activity;
import android.app.role.RoleManager;
import android.content.ActivityNotFoundException;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.os.SystemClock;
import android.provider.Settings;
import android.util.Log;
import android.widget.Toast;

import org.godotengine.godot.utils.ProcessPhoenix;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.ArrayList;
import java.util.List;

/**
 * O JOGO ABRE SOZINHO AO LIGAR A TV - a TV Box é só do jogo.
 * O mesmo InicioDaTv do Dragon Bowling / Strike Kids, com um passo a mais
 * na frente (prepararPeloRoot).
 *
 * 0. O JOGO SE PREPARA SOZINHO, SEM PERGUNTAR NADA, na primeira vez que
 *    abre (prepararSozinho): pela conta de administrador da TV Box (root,
 *    "su" - comum nas TV Box) ou pelo adb da própria TV (AdbDaTv; com a
 *    depuração aberta sem senha, também não pergunta nada). Os dois fazem o
 *    mesmo: o jogo vira a TELA INICIAL (a ROM continua instalada, só não é
 *    mais a primeira tela), "Sobrepor a outros apps" permitido e TV sempre
 *    ligada. Daí em diante, ligou a TV, abre o jogo.
 * 1. TELA INICIAL (StrikeInicioAtivo): escolhida, é ela que o Android abre
 *    ao ligar, ao voltar para o início e a cada HOME. estado() diz se já é;
 *    escolher() abre a escolha do Android - só se o passo 0 não conseguiu.
 * 2. "LIGOU" (StrikeLigou) + O GUARDA (StrikeSempre): abrem o jogo depois
 *    que a TV liga e o trazem de volta se outra tela ficar por cima. No
 *    Android 10+ precisam de "Sobrepor a outros apps" (podeAbrirDeFundo).
 * 3. VOLTA DA ESPERA (ouvirTela): desligada pelo controle e ligada de
 *    novo, o jogo reinicia do zero.
 * 4. SAÍDA DO OPERADOR: sairParaTv() (HOME 5 vezes seguidas).
 */
final class InicioDaTv {

	private static final String TAG = "StrikeSerial";
	/**
	 * A CHAVE DO "ABRIR SOZINHO AO LIGAR".
	 * false (hoje): quem abre o jogo quando a TV Box liga é o app AUTO START
	 * instalado na caixa. O jogo não se põe como tela inicial, não ouve o
	 * "ligou", não liga o guarda, não mexe na TV pelo root / adb e não pede
	 * nada na tela. TODO O CÓDIGO CONTINUA AQUI, só desligado.
	 * PARA VOLTAR A ABRIR SOZINHO (sem o auto start):
	 *   1. aqui: ABRIR_SOZINHO = true;
	 *   2. AndroidManifest.xml deste plugin: android:enabled="true" em
	 *      StrikeInicioAtivo, StrikeLigou e StrikeSempre;
	 *   3. scripts/arduino_bridge.gd: ABRIR_SOZINHO := true;
	 *   4. sh tools/android/StrikeSerial/construir.sh e gerar o APK.
	 * O Arduino (permissão USB guardada, StrikeArduinoAtivo / UsbPadrao) não
	 * depende desta chave: funciona igual com o auto start.
	 */
	static final boolean ABRIR_SOZINHO = false;
	static final int PEDIDO_PAPEL = 7501;
	private static final String PREFS = "golflash_inicio";
	private static final int VEZES_PARA_SAIR = 5;
	private static final long JANELA_SAIR_MS = 10000;
	private static final long APAGADA_PARA_REINICIAR_MS = 10000;
	private static final long ESPERA_AO_ACENDER_MS = 1500;

	private static long pedidoEm = 0;
	private static boolean pedidoSozinho = false;
	private static long apagouEm = 0;
	private static BroadcastReceiver tela;

	private InicioDaTv() {
	}

	private static Intent home() {
		return new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME);
	}

	/** Abre uma tela de outro app; false se a TV não tem essa tela. */
	private static boolean abrir(Context c, Intent i) {
		try {
			i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			c.startActivity(i);
			return true;
		} catch (ActivityNotFoundException e) {
			return false;
		} catch (Throwable t) {
			Log.i(TAG, "inicio: " + t);
			return false;
		}
	}

	/** O jogo, como o lançador o abre (só traz para a frente se já está aberto). */
	static void abrirJogo(Context c) {
		Intent jogo = c.getPackageManager().getLaunchIntentForPackage(c.getPackageName());
		if (jogo != null) {
			jogo.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
			c.startActivity(jogo);
		}
	}

	// ------------------------------------------------------------ tela inicial
	/** A tela inicial que o Android abre hoje (null, ou a janela de escolha). */
	private static ResolveInfo padrao(Context c) {
		return c.getPackageManager().resolveActivity(home(), PackageManager.MATCH_DEFAULT_ONLY);
	}

	private static boolean ehCandidata(Context c, ResolveInfo ri) {
		List<ResolveInfo> todas = c.getPackageManager().queryIntentActivities(home(), PackageManager.MATCH_DEFAULT_ONLY);
		for (ResolveInfo r : todas) {
			if (r.activityInfo.packageName.equals(ri.activityInfo.packageName) && r.activityInfo.name.equals(ri.activityInfo.name)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * A tela inicial do jogo está ligada? O PREPARAR_TV.bat -DevolverTv a
	 * desliga (a TV volta a ser TV): aí o jogo não pede mais nada.
	 */
	static boolean telaDoJogoLigada(Context c) {
		try {
			int e = c.getPackageManager().getComponentEnabledSetting(new ComponentName(c, StrikeInicioAtivo.class));
			return e != PackageManager.COMPONENT_ENABLED_STATE_DISABLED
					&& e != PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER;
		} catch (Throwable t) {
			return true;
		}
	}

	/**
	 * COM O "ABRIR SOZINHO" DESLIGADO a tela inicial do jogo vem desligada no
	 * manifesto. Mas uma caixa preparada por uma versão anterior pode ter
	 * ficado com a tela da ROM desligada: sem nenhuma tela inicial ela não
	 * abriria nada. Se não existe outra tela inicial ligada, a do jogo é
	 * religada (nada aparece na tela). true = religou.
	 */
	static boolean garantirTelaInicial(Context c) {
		try {
			PackageManager pm = c.getPackageManager();
			for (ResolveInfo r : pm.queryIntentActivities(home(), PackageManager.MATCH_DEFAULT_ONLY)) {
				if (r.activityInfo != null && r.priority >= 0 && !r.activityInfo.packageName.equals("android")) {
					return false;   // a TV tem tela inicial (a da ROM ou a do jogo)
				}
			}
			pm.setComponentEnabledSetting(new ComponentName(c, StrikeInicioAtivo.class),
					PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP);
			Log.i(TAG, "inicio: a TV estava sem tela inicial: a do jogo foi religada");
			return true;
		} catch (Throwable t) {
			Log.i(TAG, "inicio: garantir tela inicial: " + t);
			return false;
		}
	}

	/** "jogo" (a TV já abre o jogo), "escolher" (o Android ainda pergunta) ou "outra|Nome". */
	static String estado(Context c) {
		ResolveInfo ri = padrao(c);
		if (ri == null || ri.activityInfo == null) {
			return "escolher";
		}
		if (ri.activityInfo.packageName.equals(c.getPackageName())) {
			return "jogo";
		}
		// sem uma escolhida, o Android devolve a própria janela de escolha
		if (!ehCandidata(c, ri)) {
			return "escolher";
		}
		return "outra|" + ri.loadLabel(c.getPackageManager());
	}

	/**
	 * Abre a escolha da tela inicial: "ja" (já é o jogo), "papel" (a janela do
	 * Android 10+), "ajustes", "escolha" (a janela "Sempre / Só uma vez"),
	 * "app" (a página da tela inicial da TV: "Limpar padrões"), "config" ou ""
	 * (nada abriu). sozinho (o jogo pedindo na tela de espera): só as janelas
	 * de escolha, nunca a página do app nem os ajustes gerais.
	 */
	static String escolher(Activity a, boolean sozinho) {
		String agora = estado(a);
		if (agora.equals("jogo")) {
			return "ja";
		}
		pedidoSozinho = sozinho;
		if (Build.VERSION.SDK_INT >= 29 && pedirPapel(a)) {
			return "papel";
		}
		return semPapel(a, agora, sozinho);
	}

	private static boolean pedirPapel(Activity a) {
		try {
			RoleManager rm = a.getSystemService(RoleManager.class);
			if (rm == null || !rm.isRoleAvailable(RoleManager.ROLE_HOME) || rm.isRoleHeld(RoleManager.ROLE_HOME)) {
				return false;
			}
			pedidoEm = SystemClock.elapsedRealtime();
			a.startActivityForResult(rm.createRequestRoleIntent(RoleManager.ROLE_HOME), PEDIDO_PAPEL);
			return true;
		} catch (Throwable t) {
			Log.i(TAG, "inicio: papel: " + t);
			return false;
		}
	}

	/** A janela do papel voltou: se ela nem apareceu (TV sem essa janela), segue pelos ajustes. */
	static void depoisDoPapel(Activity a, int resultado) {
		if (resultado == Activity.RESULT_OK || SystemClock.elapsedRealtime() - pedidoEm > 1500) {
			return;
		}
		String agora = estado(a);
		if (!agora.equals("jogo")) {
			semPapel(a, agora, pedidoSozinho);
		}
	}

	private static String semPapel(Activity a, String agora, boolean sozinho) {
		if (abrir(a, new Intent(Settings.ACTION_HOME_SETTINGS))) {
			return "ajustes";
		}
		if (agora.equals("escolher") && abrir(a, home())) {
			return "escolha";
		}
		if (sozinho) {
			return "";
		}
		ResolveInfo ri = padrao(a);
		if (ri != null && ri.activityInfo != null && !ri.activityInfo.packageName.equals(a.getPackageName())
				&& abrir(a, new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + ri.activityInfo.packageName)))) {
			return "app";
		}
		if (abrir(a, new Intent(Settings.ACTION_SETTINGS))) {
			return "config";
		}
		return "";
	}

	// ------------------------------------------------------------ pelo adb da própria TV
	private static final int PORTA_ADB = 5555;
	private static final String DESLIGADAS = "/data/local/tmp/golflash_telas_desligadas.txt";

	/**
	 * O JOGO SE PREPARA SOZINHO: com a Depuração USB ligada (Opções do
	 * desenvolvedor), entra no adb da própria TV (AdbDaTv) e faz o mesmo do
	 * PREPARAR_TV.bat - a tela inicial do jogo ligada e escolhida, as telas da
	 * TV desligadas (só depois de conferir a do jogo), "Sobrepor" permitido e
	 * TV sempre ligada. A TV pergunta "Permitir depuração?" uma vez (no
	 * máximo uma vez a cada vez que a TV liga); com "Sempre permitir", nunca
	 * mais. Devolve: "pronta", "incompleta", "adb_desligado" (nada aparece),
	 * "sem_permissao", "devolvida" (o -DevolverTv desligou a tela do jogo)
	 * ou "erro: ...". Demorado: nunca na linha da tela.
	 */
	static String prepararPeloAdb(Context c) {
		String r = prepararPeloAdbSemGuardar(c);
		c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString("adb", r.startsWith("erro") ? "erro" : r).commit();
		return r;
	}

	private static String prepararPeloAdbSemGuardar(Context c) {
		if (!telaDoJogoLigada(c)) {
			return "devolvida";
		}
		AdbDaTv adb;
		try {
			adb = AdbDaTv.conectar("127.0.0.1", PORTA_ADB, 1500);
		} catch (IOException e) {
			return "adb_desligado";
		}
		try {
			SharedPreferences p = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
			long ligou = ligouEm(c);
			boolean podePerguntar = p.getLong("adb_perguntou", Long.MIN_VALUE) != ligou;
			if (podePerguntar) {
				p.edit().putLong("adb_perguntou", ligou).commit();
			}
			if (!adb.entrar(chaveDoJogo(c), "GolFlash@tv", podePerguntar, 5000, 120000)) {
				return "sem_permissao";
			}
			String saida = adb.shell(comandoPreparar(c), 60000);
			Log.i(TAG, "inicio: pelo adb: " + saida.trim().replace('\n', ' '));
			return saida.contains("TV_PRONTA") ? "pronta" : "incompleta";
		} catch (Throwable t) {
			Log.i(TAG, "inicio: pelo adb: " + t);
			return "erro: " + t;
		} finally {
			adb.close();
		}
	}

	/** Um número que muda a cada vez que a TV liga (para perguntar no máximo uma vez). */
	private static long ligouEm(Context c) {
		try {
			int vezes = Settings.Global.getInt(c.getContentResolver(), "boot_count", -1);
			if (vezes >= 0) {
				return vezes;
			}
		} catch (Throwable ignored) {
		}
		return (System.currentTimeMillis() - SystemClock.elapsedRealtime()) / 600000L;
	}

	/** A chave do jogo para o adb da TV: criada uma vez e guardada no jogo. */
	private static KeyPair chaveDoJogo(Context c) throws Exception {
		File priv = new File(c.getFilesDir(), "adb_chave.pk8");
		File pub = new File(c.getFilesDir(), "adb_chave.pub");
		KeyFactory kf = KeyFactory.getInstance("RSA");
		if (priv.exists() && pub.exists()) {
			try {
				return new KeyPair(kf.generatePublic(new X509EncodedKeySpec(lerTudo(pub))),
						kf.generatePrivate(new PKCS8EncodedKeySpec(lerTudo(priv))));
			} catch (Throwable estragada) {
				Log.i(TAG, "inicio: chave do adb estragada: nova");
			}
		}
		KeyPairGenerator g = KeyPairGenerator.getInstance("RSA");
		g.initialize(2048);
		KeyPair k = g.generateKeyPair();
		gravarTudo(priv, k.getPrivate().getEncoded());
		gravarTudo(pub, k.getPublic().getEncoded());
		return k;
	}

	private static byte[] lerTudo(File f) throws IOException {
		RandomAccessFile r = new RandomAccessFile(f, "r");
		try {
			byte[] b = new byte[(int) r.length()];
			r.readFully(b);
			return b;
		} finally {
			r.close();
		}
	}

	private static void gravarTudo(File f, byte[] b) throws IOException {
		FileOutputStream o = new FileOutputStream(f);
		try {
			o.write(b);
		} finally {
			o.close();
		}
	}

	private static final String[] TELAS_DO_GOOGLE = {"com.google.android.apps.tv.launcherx",
			"com.google.android.tungsten.setupwraith", "com.google.android.tvlauncher"};

	/**
	 * As outras telas iniciais da TV (menos o jogo, os Ajustes e as de fundo,
	 * com prioridade negativa) e as do Google TV. SÓ são desligadas se a TV
	 * não aceitar o jogo como tela inicial (AdbDaTv.comandoPreparar): aí é o
	 * único jeito de ela ligar no jogo. O PREPARAR_TV.bat -DevolverTv religa.
	 */
	static List<String> outrasTelasIniciais(Context c) {
		List<String> lista = new ArrayList<String>();
		for (ResolveInfo r : c.getPackageManager().queryIntentActivities(home(), PackageManager.MATCH_DEFAULT_ONLY)) {
			if (r.activityInfo == null || r.priority < 0) {
				continue;
			}
			String p = r.activityInfo.packageName;
			if (p.equals(c.getPackageName()) || p.equals("android") || p.matches("com\\.android\\.(tv\\.)?settings") || lista.contains(p)) {
				continue;
			}
			lista.add(p);
		}
		for (String g : TELAS_DO_GOOGLE) {
			if (!lista.contains(g)) {
				lista.add(g);
			}
		}
		return lista;
	}

	/** Os comandos do PREPARAR_TV.bat para esta TV (AdbDaTv.comandoPreparar). */
	static String comandoPreparar(Context c) {
		// (+ o Arduino: o jogo vira o app padrão dele, sem janela de permissão)
		return AdbDaTv.comandoPreparar(c.getPackageName(), StrikeInicioAtivo.class.getName(), outrasTelasIniciais(c), DESLIGADAS)
				+ "; " + comandoUsb(c) + " >/dev/null";
	}

	// ------------------------------------------------------------ Android 10+
	/**
	 * ANDROID 10 OU MAIS NOVO (as TVs com Android TV 10 a 14): o Android não
	 * deixa um app abrir uma tela "de fundo" - o aviso de "ligou" (StrikeLigou)
	 * e a volta da espera (ouvirTela) ficam barrados. A exceção é o app com
	 * "Sobrepor a outros apps" (SYSTEM_ALERT_WINDOW) permitido: com ela o jogo
	 * abre sozinho ao ligar mesmo sem ser a tela inicial. No Android 7.1 (TV
	 * Box) não há essa barreira.
	 */
	static boolean podeAbrirDeFundo(Context c) {
		if (Build.VERSION.SDK_INT < 29) {
			return true;
		}
		try {
			return Settings.canDrawOverlays(c);
		} catch (Throwable t) {
			return false;
		}
	}

	/**
	 * O "SOBREPOR A OUTROS APPS", COMO UM APP DE AUTO START PEDE: abre a tela do
	 * Android já no Olho no Lance (ou a lista) com um aviso de o que fazer.
	 * Permitido uma vez, o aviso de "ligou" (StrikeLigou) abre o jogo sempre
	 * que a TV liga - e nunca mais pede. false se a TV não tem essa tela.
	 */
	static boolean pedirSobrepor(final Activity a) {
		final String aviso = "PARA O JOGO ABRIR SOZINHO AO LIGAR A TV: deixe OLHO NO LANCE "
				+ "PERMITIDO (ligado) e aperte VOLTAR. É só desta vez.";
		boolean abriu = abrir(a, new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + a.getPackageName())))
				|| abrir(a, new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION));
		if (abriu) {
			try {
				// o aviso fica por cima da tela do Android (duas vezes: uns 7 s)
				Toast.makeText(a.getApplicationContext(), aviso, Toast.LENGTH_LONG).show();
				new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
					@Override
					public void run() {
						Toast.makeText(a.getApplicationContext(), aviso, Toast.LENGTH_LONG).show();
					}
				}, 3500);
			} catch (Throwable ignored) {
			}
		}
		return abriu;
	}

	/**
	 * ACENDE A TELA DA TV ao ligar: se o Android ligou com a tela apagada (TV
	 * em espera com a placa ligada), o jogo a acende, como um aviso de alarme.
	 * Se a TV ficou desligada de verdade (só a luz vermelha), nada a fazer por
	 * aqui: é o ajuste da TV de ligar quando a energia volta.
	 */
	@SuppressWarnings("deprecation")
	static void acenderTela(Context c) {
		try {
			PowerManager pm = (PowerManager) c.getSystemService(Context.POWER_SERVICE);
			if (pm == null) {
				return;
			}
			PowerManager.WakeLock luz = pm.newWakeLock(PowerManager.SCREEN_BRIGHT_WAKE_LOCK
					| PowerManager.ACQUIRE_CAUSES_WAKEUP | PowerManager.ON_AFTER_RELEASE, "GolFlash:ligou");
			luz.acquire(20000);
		} catch (Throwable t) {
			Log.i(TAG, "inicio: acender a tela: " + t);
		}
	}

	// ------------------------------------------------------------ root
	/**
	 * PELA CONTA DE ADMINISTRADOR DA TV BOX (root): roda os mesmos comandos do
	 * adb com o "su" da caixa, sem nada aparecer na tela. "pronta",
	 * "incompleta" ou "sem_root". Demorado: nunca na linha da tela.
	 */
	static String prepararPeloRoot(Context c) {
		String comando = comandoPreparar(c);
		String[][] jeitos = {{"su", "-c", comando}, {"su", "0", "sh", "-c", comando},
				{"/system/xbin/su", "-c", comando}, {"/system/bin/su", "-c", comando}};
		String r = "sem_root";
		for (String[] j : jeitos) {
			String saida = rodar(j, 25000);
			if (saida == null) {
				continue;
			}
			Log.i(TAG, "inicio: pelo root: " + saida.trim().replace('\n', ' '));
			if (saida.contains("TV_PRONTA")) {
				r = "pronta";
				break;
			}
			if (saida.contains("SEM_TELA_DO_JOGO")) {
				r = "incompleta";
			}
		}
		c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString("root", r).commit();
		return r;
	}

	/** Roda um programa e devolve o que ele escreveu (null: não existe, falhou ou demorou). */
	private static String rodar(String[] comando, long esperaMs) {
		Process p = null;
		try {
			p = new ProcessBuilder(comando).redirectErrorStream(true).start();
			p.getOutputStream().close();
			final java.io.InputStream entrada = p.getInputStream();
			final StringBuilder sb = new StringBuilder();
			Thread leitor = new Thread(new Runnable() {
				@Override
				public void run() {
					try {
						byte[] b = new byte[2048];
						int n;
						while ((n = entrada.read(b)) > 0 && sb.length() < 16000) {
							synchronized (sb) {
								sb.append(new String(b, 0, n, "UTF-8"));
							}
						}
					} catch (Throwable ignored) {
					}
				}
			}, "GolFlashSu");
			leitor.setDaemon(true);
			leitor.start();
			leitor.join(esperaMs);
			if (leitor.isAlive()) {
				return null;   // (uma janela de "permitir root?" sem resposta)
			}
			synchronized (sb) {
				return sb.toString();
			}
		} catch (Throwable t) {
			return null;
		} finally {
			if (p != null) {
				try {
					p.destroy();
				} catch (Throwable ignored) {
				}
			}
		}
	}

	/**
	 * O JOGO SE PREPARA SOZINHO: 1o pelo root, depois pelo adb da própria TV.
	 * "pronta" (a TV já abre o jogo ao ligar) ou o motivo de não ter dado.
	 */
	static String prepararSozinho(Context c) {
		String r = prepararPeloRoot(c);
		if (r.equals("pronta")) {
			return r;
		}
		return prepararPeloAdb(c);
	}

	// ------------------------------------------------------------ Arduino sem janela
	/** O comando que roda o UsbPadrao (ver UsbPadrao.java) com a autoridade do root / do adb. */
	static String comandoUsb(Context c) {
		return "CLASSPATH=" + c.getApplicationInfo().sourceDir + " app_process /system/bin "
				+ UsbPadrao.class.getName() + " " + c.getPackageName() + " " + c.getApplicationInfo().uid + " 2>&1";
	}

	/**
	 * A PERMISSÃO USB DO ARDUINO SEM JANELA E PARA SEMPRE: pelo root da caixa
	 * ou pelo adb da própria TV (Depuração USB ligada), o jogo vira o app
	 * padrão do Arduino - o Android nunca mais pergunta. "ok" ou "sem_acesso"
	 * (a caixa não tem root nem depuração: resta a janela do Android).
	 * Demorado: nunca na linha da tela.
	 */
	static String usbSemJanela(Context c) {
		String comando = comandoUsb(c);
		String[][] jeitos = {{"su", "-c", comando}, {"su", "0", "sh", "-c", comando},
				{"/system/xbin/su", "-c", comando}, {"/system/bin/su", "-c", comando}};
		for (String[] j : jeitos) {
			String saida = rodar(j, 15000);
			if (saida != null && saida.contains("USB_PADRAO")) {
				Log.i(TAG, "usb: pelo root: " + saida.trim().replace('\n', ' '));
				if (!saida.contains("USB_PADRAO 0")) {
					return "ok";
				}
			}
		}
		AdbDaTv adb;
		try {
			adb = AdbDaTv.conectar("127.0.0.1", PORTA_ADB, 1500);
		} catch (IOException e) {
			return "sem_acesso";
		}
		try {
			SharedPreferences p = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
			long ligou = ligouEm(c);
			// (com o auto start - ABRIR_SOZINHO desligado - o jogo nunca faz a TV
			// perguntar "Permitir depuração?": só usa o adb que já o aceitou)
			boolean podePerguntar = ABRIR_SOZINHO && p.getLong("adb_perguntou", Long.MIN_VALUE) != ligou;
			if (podePerguntar) {
				p.edit().putLong("adb_perguntou", ligou).commit();
			}
			if (!adb.entrar(chaveDoJogo(c), "GolFlash@tv", podePerguntar, 5000, 120000)) {
				return "sem_acesso";
			}
			String saida = adb.shell(comando, 30000);
			Log.i(TAG, "usb: pelo adb: " + saida.trim().replace('\n', ' '));
			return saida.contains("USB_PADRAO") && !saida.contains("USB_PADRAO 0") ? "ok" : "sem_acesso";
		} catch (Throwable t) {
			Log.i(TAG, "usb: pelo adb: " + t);
			return "sem_acesso";
		} finally {
			adb.close();
		}
	}

	// ------------------------------------------------------------ estado
	/** O jogo está na frente (o plugin avisa: onMainResume / onMainPause). */
	static volatile boolean naFrente = false;

	/** O aviso de "ligou" chegou (StrikeLigou): guarda para a Central da Máquina. */
	static void anotarLigou(Context c, String acao) {
		try {
			SharedPreferences p = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
			p.edit().putLong("ligou_em", System.currentTimeMillis()).putInt("ligou_vezes", p.getInt("ligou_vezes", 0) + 1).commit();
		} catch (Throwable ignored) {
		}
	}

	/** O estado do "abrir ao ligar" para a Central da Máquina (linhas nome=valor). */
	static String relatorio(Context c) {
		SharedPreferences p = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
		String sobrepor = Build.VERSION.SDK_INT < 29 ? "nao_precisa" : (podeAbrirDeFundo(c) ? "sim" : "nao");
		long ligou = p.getLong("ligou_em", 0);
		String quando = ligou == 0 ? "nunca" : ((System.currentTimeMillis() - ligou) / 60000L) + " min";
		String est;
		try {
			est = estado(c).replace('\n', ' ');
		} catch (Throwable t) {
			est = "?";
		}
		return "android=" + Build.VERSION.RELEASE + "\nsdk=" + Build.VERSION.SDK_INT + "\ntela_inicial=" + est
				+ "\nsobrepor=" + sobrepor + "\nligou=" + quando + "\nligou_vezes=" + p.getInt("ligou_vezes", 0)
				+ "\nroot=" + p.getString("root", "") + "\nadb=" + p.getString("adb", "")
				+ "\naparelho=" + Build.MANUFACTURER + " " + Build.MODEL + "\n";
	}

	// ------------------------------------------------------------ saída
	/** A tela inicial da própria TV (a de maior prioridade que não é o jogo), ou null. */
	private static ResolveInfo outraTela(Context c) {
		PackageManager pm = c.getPackageManager();
		ResolveInfo melhor = null;
		for (ResolveInfo r : pm.queryIntentActivities(home(), PackageManager.MATCH_DEFAULT_ONLY)) {
			if (r.activityInfo == null || r.activityInfo.packageName.equals(c.getPackageName())) {
				continue;
			}
			// a "FallbackHome" dos Ajustes (só a do começo do boot) tem prioridade -1000
			if (melhor == null || r.priority > melhor.priority
					|| (r.priority == melhor.priority && sistema(r) && !sistema(melhor))) {
				melhor = r;
			}
		}
		return melhor;
	}

	private static boolean sistema(ResolveInfo r) {
		return (r.activityInfo.applicationInfo.flags & ApplicationInfo.FLAG_SYSTEM) != 0;
	}

	/**
	 * O GUARDA (StrikeSempre) traz o jogo de volta quando ele sai da tela; aqui
	 * ele espera um pouco: o operador usando a TV (HOME 5 vezes) ou o jogo
	 * pedindo uma permissão na instalação.
	 */
	static void pausarGuarda(Context c, long ms) {
		c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
				.putLong("guarda_ate", SystemClock.elapsedRealtime() + ms).commit();
	}

	static boolean guardaPausada(Context c) {
		long ate = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getLong("guarda_ate", 0);
		long agora = SystemClock.elapsedRealtime();
		// (depois de a TV religar o relógio recomeça: um "até" maior que 20 min é velho)
		return agora < ate && ate - agora <= 20 * 60000L;
	}

	/** Abre a tela inicial da própria TV (ou os ajustes): o nome dela, "config" ou "". */
	static String sairParaTv(Context c) {
		// o operador vai usar a TV: o guarda espera 15 min (HOME volta ao jogo)
		pausarGuarda(c, 15 * 60000L);
		ResolveInfo outra = outraTela(c);
		if (outra != null) {
			Intent i = home().setClassName(outra.activityInfo.packageName, outra.activityInfo.name)
					.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
			if (abrir(c, i)) {
				return outra.loadLabel(c.getPackageManager()).toString();
			}
		}
		return abrir(c, new Intent(Settings.ACTION_SETTINGS)) ? "config" : "";
	}

	/** HOME 5 vezes em 10 s (ou o jogo caindo sem parar): true = sair para a tela da TV. */
	static boolean pediuParaSair(Context c) {
		SharedPreferences p = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
		long agora = SystemClock.elapsedRealtime();
		long desde = p.getLong("desde", 0);
		int vezes = p.getInt("vezes", 0);
		if (agora < desde || agora - desde > JANELA_SAIR_MS) {
			desde = agora;
			vezes = 0;
		}
		vezes++;
		boolean sair = vezes >= VEZES_PARA_SAIR;
		p.edit().putLong("desde", sair ? 0 : desde).putInt("vezes", sair ? 0 : vezes).commit();
		return sair;
	}

	// ------------------------------------------------------------ volta da espera
	/**
	 * Tela apagada 10 s ou mais e acesa de novo = o jogo reinicia do zero.
	 * Fica ouvindo enquanto o processo do jogo viver (mesmo com o jogo
	 * fechado ou atrás de outro app).
	 */
	static void ouvirTela(Activity atividade) {
		if (tela != null) {
			return;
		}
		final Context app = atividade.getApplicationContext();
		tela = new BroadcastReceiver() {
			@Override
			public void onReceive(Context c, Intent i) {
				if (Intent.ACTION_SCREEN_OFF.equals(i.getAction())) {
					apagouEm = SystemClock.elapsedRealtime();
					return;
				}
				long apagada = apagouEm > 0 ? SystemClock.elapsedRealtime() - apagouEm : 0;
				apagouEm = 0;
				if (apagada < APAGADA_PARA_REINICIAR_MS) {
					return;
				}
				Log.i(TAG, "inicio: a TV voltou da espera (" + apagada / 1000 + " s): o jogo reinicia");
				new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
					@Override
					public void run() {
						try {
							ProcessPhoenix.triggerRebirth(app);
						} catch (Throwable t) {
							Log.i(TAG, "inicio: reiniciar: " + t);
						}
					}
				}, ESPERA_AO_ACENDER_MS);
			}
		};
		IntentFilter f = new IntentFilter(Intent.ACTION_SCREEN_OFF);
		f.addAction(Intent.ACTION_SCREEN_ON);
		try {
			app.registerReceiver(tela, f);
		} catch (Throwable t) {
			tela = null;
			Log.i(TAG, "inicio: tela: " + t);
		}
	}
}
