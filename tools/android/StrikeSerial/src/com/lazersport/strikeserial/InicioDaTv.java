package com.lazersport.strikeserial;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.provider.Settings;
import android.util.Log;

import org.godotengine.godot.utils.ProcessPhoenix;

/**
 * O JOGO ABRE SOZINHO DEPOIS QUE A TV LIGA - SEM TOMAR O LUGAR DA ROM.
 *
 * A tela inicial da TV (a ROM) continua sendo a dela: ela abre normalmente
 * e o jogo entra POR CIMA logo depois. O jogo NÃO é uma "tela inicial" do
 * Android: nenhuma janela "Sempre / Só uma vez", nenhum conflito com a ROM.
 * Três caminhos, um reforça o outro:
 *
 * 1. A TV LIGOU (StrikeLigou, aviso BOOT_COMPLETED do Android): alguns
 *    segundos depois da tela da ROM o jogo é aberto. Até o Android 9 isso
 *    basta. No Android 10 ou mais novo o sistema só deixa um app abrir uma
 *    tela "sozinho" se ele tiver a permissão "aparecer sobre outros apps":
 *    podeAbrirSozinho() diz se tem, pedirPermissao() abre a tela dela (uma
 *    chave para ligar, uma vez só).
 * 2. O ARDUINO NO USB (StrikeArduinoAtivo): com "Usar por padrão" marcado,
 *    é o próprio Android que abre o jogo ao enxergar o Arduino - ao ligar a
 *    TV e ao encaixar o cabo - em qualquer versão, sem permissão extra.
 * 3. VOLTA DA ESPERA: desligada pelo CONTROLE, a TV só dorme. ouvirTela()
 *    percebe a tela apagar e acender: depois de 10 s ou mais apagada, o
 *    jogo reinicia do zero e vem para a frente.
 *
 * O Android só entrega o aviso de "ligou" a um app que já foi aberto uma
 * vez: depois de instalar, abra o jogo uma vez pelo controle.
 */
final class InicioDaTv {

	private static final String TAG = "StrikeSerial";
	private static final long APAGADA_PARA_REINICIAR_MS = 10000;
	private static final long ESPERA_AO_ACENDER_MS = 1500;

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
		if (jogo == null) {
			// TV que só lista apps de TV (leanback)
			jogo = c.getPackageManager().getLeanbackLaunchIntentForPackage(c.getPackageName());
		}
		if (jogo != null) {
			jogo.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
			c.startActivity(jogo);
		}
	}

	// ------------------------------------------------------------ permissão
	/** O Android deixa o jogo abrir sozinho depois de ligar? (até o Android 9, sempre) */
	static boolean podeAbrirSozinho(Context c) {
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
	 * Abre a tela "aparecer sobre outros apps" do jogo (Android 10+): "ja"
	 * (não precisa), "permissao" (abriu a tela: ligue a chave), "app" (abriu
	 * a página do jogo nos ajustes) ou "" (a TV não tem essa tela: vale o
	 * caminho do Arduino no USB).
	 */
	static String pedirPermissao(Context c) {
		if (podeAbrirSozinho(c)) {
			return "ja";
		}
		Uri pacote = Uri.parse("package:" + c.getPackageName());
		if (abrir(c, new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, pacote))) {
			return "permissao";
		}
		if (abrir(c, new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))) {
			return "permissao";
		}
		if (abrir(c, new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pacote))) {
			return "app";
		}
		return "";
	}

	// ------------------------------------------------------------ saída
	/** A tela inicial da TV (a de maior prioridade), ou null. */
	private static ResolveInfo telaDaTv(Context c) {
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

	/** Sai do jogo para a tela inicial da TV: "tv", "config" (os ajustes) ou "". */
	static String sairParaTv(Context c) {
		if (abrir(c, home())) {
			return "tv";
		}
		ResolveInfo outra = telaDaTv(c);
		if (outra != null && abrir(c, home().setClassName(outra.activityInfo.packageName, outra.activityInfo.name))) {
			return "tv";
		}
		return abrir(c, new Intent(Settings.ACTION_SETTINGS)) ? "config" : "";
	}

	// ------------------------------------------------------------ volta da espera
	/**
	 * Tela apagada 10 s ou mais e acesa de novo = o jogo reinicia do zero.
	 * Fica ouvindo enquanto o processo do jogo viver.
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
