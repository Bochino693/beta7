package com.lazersport.strikeserial;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.UserManager;
import android.util.Log;

/**
 * PERMISSÃO DO ARDUINO UMA VEZ SÓ.
 *
 * Com este filtro (res/xml/strike_usb_arduino.xml) a janela de permissão
 * USB do Android mostra a caixa "Usar por padrão": marcada uma vez, o
 * Android guarda o jogo como o app padrão do Arduino e passa a DAR A
 * PERMISSÃO SOZINHO toda vez que o Arduino aparece - inclusive ao ligar a
 * caixa, antes de o jogo abrir. É assim que o jogo aberto pelo app de auto
 * start já encontra o Arduino liberado, sem perguntar nada.
 *
 * AO LIGAR A CAIXA o Android faz isso bem no começo da inicialização, com o
 * armazenamento ainda "travado" (Android 9 ou mais novo). Por isso esta
 * atividade é directBootAware no manifesto: sem isso o Android não a
 * enxerga nessa hora, não acha o app padrão e não dá a permissão - e o
 * jogo tinha de pedir a janela de novo a cada vez que a caixa ligava.
 * A permissão é dada pelo Android ANTES de abrir esta atividade; aqui só
 * falta trazer o jogo para a frente - e, com a caixa ainda travada, nem
 * isso (o jogo ainda não pode abrir: quem abre depois é o auto start).
 */
public class StrikeArduinoAtivo extends Activity {
	@Override
	protected void onCreate(Bundle estado) {
		super.onCreate(estado);
		try {
			if (destravado()) {
				Intent jogo = getPackageManager().getLaunchIntentForPackage(getPackageName());
				if (jogo != null) {
					jogo.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
					startActivity(jogo);
				}
			} else {
				Log.i("StrikeSerial", "usb: Arduino visto com a caixa ainda iniciando: a permissão já foi dada; o jogo abre depois");
			}
		} catch (Throwable ignored) {
		}
		finish();
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
}
