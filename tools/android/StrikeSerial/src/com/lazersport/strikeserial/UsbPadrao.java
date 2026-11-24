package com.lazersport.strikeserial;

import android.hardware.usb.UsbDevice;
import android.os.Bundle;
import android.os.IBinder;

import java.lang.reflect.Method;

/**
 * A PERMISSÃO USB DO ARDUINO PARA SEMPRE, SEM JANELA.
 *
 * Este programinha NÃO roda dentro do jogo: o jogo pede para a conta de
 * administrador da TV Box (root) ou para o adb da própria TV rodá-lo
 * (InicioDaTv.usbSemJanela):
 *
 *   CLASSPATH=<apk do jogo> app_process /system/bin \
 *       com.lazersport.strikeserial.UsbPadrao <pacote> <uid>
 *
 * Com a autoridade dessas contas ele fala com o serviço USB do Android e,
 * para cada Arduino / chip USB-serial ligado:
 *   - define o jogo como o app PADRÃO daquele aparelho (é o mesmo que marcar
 *     "Usar por padrão" na janela do Android - fica guardado, vale depois de
 *     desligar a TV Box e de tirar e pôr o cabo);
 *   - dá a permissão agora.
 * Depois disso o Android nunca mais pergunta nada sobre o Arduino.
 * Escreve "USB_PADRAO n" (n aparelhos acertados) ou "USB_ERRO ...".
 */
public final class UsbPadrao {

	private UsbPadrao() {
	}

	/** Os fabricantes do res/xml/strike_usb_arduino.xml. */
	private static final int[] FABRICANTES = {0x2341, 0x2A03, 0x1A86, 0x0403, 0x10C4, 0x1B4F, 0x239A};

	public static void main(String[] a) {
		try {
			String pacote = a[0];
			int uid = Integer.parseInt(a[1]);
			Class<?> servicos = Class.forName("android.os.ServiceManager");
			IBinder b = (IBinder) servicos.getMethod("getService", String.class).invoke(null, "usb");
			Class<?> tipo = Class.forName("android.hardware.usb.IUsbManager");
			Object usb = Class.forName("android.hardware.usb.IUsbManager$Stub").getMethod("asInterface", IBinder.class).invoke(null, b);
			Bundle lista = new Bundle();
			tipo.getMethod("getDeviceList", Bundle.class).invoke(usb, lista);
			Method padrao = tipo.getMethod("setDevicePackage", UsbDevice.class, String.class, int.class);
			Method permitir = tipo.getMethod("grantDevicePermission", UsbDevice.class, int.class);
			int certos = 0;
			for (String chave : lista.keySet()) {
				Object o = lista.get(chave);
				if (!(o instanceof UsbDevice)) {
					continue;
				}
				UsbDevice d = (UsbDevice) o;
				boolean nosso = false;
				for (int f : FABRICANTES) {
					if (d.getVendorId() == f) {
						nosso = true;
					}
				}
				if (!nosso) {
					continue;
				}
				boolean ok = false;
				try {
					padrao.invoke(usb, d, pacote, uid / 100000);
					ok = true;
				} catch (Throwable t) {
					System.out.println("USB_AVISO padrao: " + causa(t));
				}
				try {
					permitir.invoke(usb, d, uid);
					ok = true;
				} catch (Throwable t) {
					System.out.println("USB_AVISO permitir: " + causa(t));
				}
				if (ok) {
					certos++;
				}
			}
			System.out.println("USB_PADRAO " + certos);
		} catch (Throwable t) {
			System.out.println("USB_ERRO " + causa(t));
		}
	}

	private static String causa(Throwable t) {
		return String.valueOf(t.getCause() != null ? t.getCause() : t);
	}
}
