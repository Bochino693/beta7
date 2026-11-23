package com.lazersport.strikeserial;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.UserManager;
import android.util.Log;

/**
 * O JOGO ABRE SOZINHO AO LIGAR A TV.
 *
 * Esta atividade invisível é uma TELA INICIAL do Android (filtro HOME no
 * manifesto). Escolhida como a tela inicial da TV ("Sempre"), é ela que o
 * Android abre ao ligar a TV, ao voltar do modo de espera para o início e a
 * cada HOME do controle: só traz o jogo para a frente (ou abre) e fecha.
 *
 * directBootAware (no manifesto): o Android procura a tela inicial JÁ NO
 * COMEÇO da inicialização, antes de "destravar" o armazenamento. Uma tela
 * inicial que não é directBootAware some da lista nessa hora, a lista fica
 * diferente da do dia em que você escolheu "Sempre" e o Android JOGA FORA a
 * escolha - por isso ele voltava a perguntar a cada vez que a TV Box ligava.
 * Com directBootAware a lista é sempre a mesma e a escolha fica guardada.
 * Nessa hora o jogo ainda não pode abrir (o armazenamento dele está
 * travado): esta atividade espera destravar (ESPERA_MS no máximo) e abre.
 *
 * HOME apertado 5 vezes seguidas no controle remoto abre a tela inicial da
 * própria TV (InicioDaTv.pediuParaSair): a saída do operador.
 */
public class StrikeInicioAtivo extends Activity {

	private static final String TAG = "StrikeSerial";
	private static final long OLHAR_MS = 300;
	private static final long ESPERA_MS = 90000;

	private final Handler relogio = new Handler(Looper.getMainLooper());
	private long desde;

	@Override
	protected void onCreate(Bundle estado) {
		super.onCreate(estado);
		desde = android.os.SystemClock.elapsedRealtime();
		if (destravado()) {
			abrir();
		} else {
			Log.i(TAG, "inicio: a TV ainda esta destravando o armazenamento: o jogo abre em seguida");
			relogio.postDelayed(esperar, OLHAR_MS);
		}
	}

	private boolean destravado() {
		if (Build.VERSION.SDK_INT < 24) {
			return true;
		}
		try {
			UserManager um = (UserManager) getSystemService(Context.USER_SERVICE);
			return um == null || um.isUserUnlocked();
		} catch (Throwable t) {
			return true;
		}
	}

	private final Runnable esperar = new Runnable() {
		@Override
		public void run() {
			if (isFinishing()) {
				return;
			}
			if (destravado() || android.os.SystemClock.elapsedRealtime() - desde > ESPERA_MS) {
				abrir();
			} else {
				relogio.postDelayed(this, OLHAR_MS);
			}
		}
	};

	private void abrir() {
		try {
			if (InicioDaTv.pediuParaSair(this)) {
				InicioDaTv.sairParaTv(this);
			} else {
				InicioDaTv.abrirJogo(this);
			}
		} catch (Throwable t) {
			Log.i(TAG, "inicio: tela inicial: " + t);
		}
		finish();
	}

	@Override
	protected void onDestroy() {
		relogio.removeCallbacks(esperar);
		super.onDestroy();
	}
}
