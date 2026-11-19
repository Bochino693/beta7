package com.lazersport.strikeserial;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

/**
 * A TV LIGOU: a tela da ROM abre primeiro e, alguns segundos depois, o jogo
 * entra por cima dela. Duas tentativas (a ROM de algumas TV Box demora e
 * volta para a frente): se o jogo já está na frente, a segunda não faz nada.
 * QUICKBOOT_POWERON: o "ligou" das TVs e TV Boxes com inicialização rápida.
 * No Android 10+ o sistema só deixa abrir daqui com a permissão "aparecer
 * sobre outros apps" (InicioDaTv.podeAbrirSozinho) - sem ela vale o caminho
 * do Arduino no USB (StrikeArduinoAtivo).
 */
public class StrikeLigou extends BroadcastReceiver {
	private static final long PRIMEIRA_MS = 4000;
	private static final long SEGUNDA_MS = 9000;

	@Override
	public void onReceive(Context contexto, Intent i) {
		final Context c = contexto.getApplicationContext();
		final PendingResult pendente = goAsync();   // segura o processo até abrir
		Log.i("StrikeSerial", "inicio: a TV ligou (" + i.getAction() + "): o jogo abre em " + PRIMEIRA_MS / 1000 + " s"
				+ (InicioDaTv.podeAbrirSozinho(c) ? "" : " (sem a permissao de abrir sozinho)"));
		Handler h = new Handler(Looper.getMainLooper());
		h.postDelayed(new Runnable() {
			@Override
			public void run() {
				tentar(c);
			}
		}, PRIMEIRA_MS);
		h.postDelayed(new Runnable() {
			@Override
			public void run() {
				tentar(c);
				try {
					pendente.finish();
				} catch (Throwable ignored) {
				}
			}
		}, SEGUNDA_MS);
	}

	private static void tentar(Context c) {
		try {
			InicioDaTv.abrirJogo(c);
		} catch (Throwable t) {
			Log.i("StrikeSerial", "inicio: ligou: " + t);
		}
	}
}
