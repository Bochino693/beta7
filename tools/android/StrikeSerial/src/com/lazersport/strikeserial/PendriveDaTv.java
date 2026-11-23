package com.lazersport.strikeserial;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.UriPermission;
import android.database.Cursor;
import android.net.Uri;
import android.os.Environment;
import android.os.ParcelFileDescriptor;
import android.provider.DocumentsContract;
import android.util.Log;
import android.webkit.MimeTypeMap;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;

/**
 * O PENDRIVE DO MODO FEIRA (os cadastros dos jogadores vão para ele).
 *
 * O Android deixa um app escrever num pendrive por dois caminhos, e o jogo
 * usa os dois (scripts/leads.gd escolhe):
 *
 * 1. DIRETO NA PASTA, sem pedir nada: pastaDireta() acha um pendrive / cartão
 *    montado e testa onde dá para escrever - primeiro a raiz dele (algumas
 *    caixas deixam; no Android 11+ com "acesso a todos os arquivos") e, se
 *    não der, a pasta "Android/data/<jogo>/files" que o Android cria e
 *    entrega ao jogo dentro do pendrive. lerArquivo() / gravarArquivo().
 *
 * 2. A PASTA QUE O OPERADOR ESCOLHEU (o seletor de pastas do Android):
 *    escolher() abre o seletor; o operador entra no pendrive e aperta "usar
 *    esta pasta" UMA vez. O Android guarda a autorização (ela vale depois
 *    de desligar a TV e de tirar e pôr o mesmo pendrive). ler() / gravar()
 *    escrevem ali, na raiz do pendrive.
 *
 * Tudo aqui devolve "" / false em vez de estourar: sem pendrive, os
 * cadastros ficam guardados no jogo e vão para o pendrive quando ele vier.
 */
final class PendriveDaTv {

	private PendriveDaTv() {
	}

	private static final String TAG = "StrikeSerial";
	static final int PEDIDO_PASTA = 7342;
	private static final String PREFS = "olho_pendrive";
	private static final String CHAVE = "pasta";
	private static final Charset UTF8 = Charset.forName("UTF-8");
	private static final int LIMITE = 48 * 1024 * 1024;

	// ------------------------------------------------- 1. pastas do pendrive
	static final String PASTA = "OlhoNoLance_Leads";
	private static volatile String pastaBoa = "";

	/**
	 * A pasta OlhoNoLance_Leads de um pendrive espetado onde o jogo CONSEGUE
	 * escrever ("" = nenhuma). Tenta primeiro a raiz de cada pendrive e, se o
	 * Android não deixar, a pasta do próprio jogo dentro dele
	 * (Android/data/<jogo>/files), que não precisa de permissão.
	 * (Os arquivos passam por aqui, em Java puro: o leitor de arquivos do
	 * Godot não enxerga pendrives.)
	 */
	static String pastaDireta(Context c) {
		String boa = pastaBoa;
		if (boa.length() > 0) {
			File f = new File(boa);
			if (f.isDirectory() && f.canWrite()) {
				return boa;
			}
			pastaBoa = "";
		}
		List<File> raizes = new ArrayList<File>();
		List<File> doJogo = new ArrayList<File>();
		try {
			File[] pastas = c.getExternalFilesDirs(null);
			// (a 1a é sempre a memória da própria TV Box)
			for (int i = 1; pastas != null && i < pastas.length; i++) {
				File p = pastas[i];
				if (p == null) {
					continue;
				}
				try {
					if (!Environment.MEDIA_MOUNTED.equals(Environment.getExternalStorageState(p))
							|| Environment.isExternalStorageEmulated(p)) {
						continue;
					}
				} catch (Throwable t) {
					// (caixa que não sabe dizer: vale o teste de escrita)
				}
				File raiz = p;
				for (int n = 0; n < 4 && raiz != null; n++) {
					raiz = raiz.getParentFile();   // Android/data/<jogo>/files
				}
				if (raiz != null) {
					raizes.add(raiz);
				}
				doJogo.add(p);
			}
		} catch (Throwable t) {
			Log.w(TAG, "pendrive: " + t);
		}
		for (String base : new String[] {"/storage", "/storage/external_storage", "/mnt/media_rw", "/mnt/usb_storage",
				"/mnt/usb", "/mnt/usbhost"}) {
			File[] dentro = null;
			try {
				dentro = new File(base).listFiles();
			} catch (Throwable t) {
				// sem acesso
			}
			if (dentro == null) {
				continue;
			}
			for (File f : dentro) {
				String n = f.getName().toLowerCase();
				if (n.equals("emulated") || n.equals("self") || n.equals("enc_emulated") || n.equals("knox-emulated")
						|| n.equals("external_storage") || n.startsWith("sdcard") || n.startsWith(".")) {
					continue;
				}
				if (f.isDirectory() && !raizes.contains(f)) {
					raizes.add(f);
				}
			}
		}
		for (File r : raizes) {
			String p = testar(new File(r, PASTA));
			if (p != null) {
				pastaBoa = p;
				return p;
			}
		}
		for (File d : doJogo) {
			String p = testar(new File(d, PASTA));
			if (p != null) {
				pastaBoa = p;
				return p;
			}
		}
		return "";
	}

	private static String testar(File pasta) {
		try {
			File copia = new File(pasta, "copia_de_seguranca");
			if (!copia.isDirectory() && !copia.mkdirs()) {
				return null;
			}
			File t = new File(pasta, ".teste_de_escrita");
			FileOutputStream o = new FileOutputStream(t);
			o.write(111);
			o.close();
			boolean ok = t.length() == 1;
			t.delete();
			return ok ? pasta.getAbsolutePath() : null;
		} catch (Throwable e) {
			return null;
		}
	}

	/** O texto (UTF-8) de um arquivo do pendrive; "" se não existe. */
	static String lerArquivo(String caminho) {
		FileInputStream in = null;
		try {
			File f = new File(caminho);
			if (!f.isFile() || f.length() > LIMITE) {
				return "";
			}
			in = new FileInputStream(f);
			ByteArrayOutputStream tudo = new ByteArrayOutputStream();
			byte[] b = new byte[16384];
			int n;
			while ((n = in.read(b)) > 0) {
				tudo.write(b, 0, n);
			}
			return new String(tudo.toByteArray(), UTF8);
		} catch (Throwable t) {
			return "";
		} finally {
			if (in != null) {
				try {
					in.close();
				} catch (Throwable t) {
					// nada
				}
			}
		}
	}

	/**
	 * Grava um arquivo da pasta OlhoNoLance_Leads: inteiro num arquivo novo,
	 * mandado para o pendrive de verdade (sync) e só então posto no lugar do
	 * antigo. Tirar o pendrive no meio não deixa arquivo pela metade.
	 */
	static boolean gravarArquivo(String caminho, String texto) {
		if (!caminho.contains("/" + PASTA + "/")) {
			return false;
		}
		FileOutputStream o = null;
		try {
			File f = new File(caminho);
			File pai = f.getParentFile();
			if (pai != null && !pai.isDirectory()) {
				pai.mkdirs();
			}
			byte[] bytes = texto.getBytes(UTF8);
			File novo = new File(caminho + ".tmp");
			o = new FileOutputStream(novo);
			o.write(bytes);
			o.flush();
			try {
				o.getFD().sync();
			} catch (Throwable t) {
				// (o Android manda mais tarde)
			}
			o.close();
			o = null;
			if (novo.length() != bytes.length) {
				novo.delete();
				return false;
			}
			if (f.exists() && !f.delete()) {
				novo.delete();
				return false;
			}
			return novo.renameTo(f);
		} catch (Throwable t) {
			Log.w(TAG, "pendrive: gravar " + caminho + ": " + t);
			return false;
		} finally {
			if (o != null) {
				try {
					o.close();
				} catch (Throwable t) {
					// nada
				}
			}
		}
	}

	// ------------------------------------------- 2. a pasta que foi escolhida
	/** Abre o seletor de pastas do Android: true se a TV tem um. */
	static boolean escolher(Activity a) {
		try {
			Intent i = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
			i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION
					| Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION | Intent.FLAG_GRANT_PREFIX_URI_PERMISSION);
			if (i.resolveActivity(a.getPackageManager()) == null) {
				return false;
			}
			a.startActivityForResult(i, PEDIDO_PASTA);
			return true;
		} catch (Throwable t) {
			Log.w(TAG, "pendrive: sem seletor de pastas: " + t);
			return false;
		}
	}

	/** O operador escolheu (ou desistiu): guarda a autorização para sempre. */
	static void depoisDeEscolher(Activity a, int resultado, Intent dados) {
		if (resultado != Activity.RESULT_OK || dados == null || dados.getData() == null) {
			return;
		}
		Uri u = dados.getData();
		try {
			a.getContentResolver().takePersistableUriPermission(u,
					Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
		} catch (Throwable t) {
			Log.w(TAG, "pendrive: a autorizacao nao ficou guardada: " + t);
		}
		a.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(CHAVE, u.toString()).apply();
	}

	/** A pasta escolhida, se o pendrive dela está espetado agora (senão null). */
	private static Uri pasta(Context c) {
		String s = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(CHAVE, "");
		if (s == null || s.length() == 0) {
			return null;
		}
		Uri u = Uri.parse(s);
		try {
			boolean vale = false;
			List<UriPermission> dadas = c.getContentResolver().getPersistedUriPermissions();
			for (UriPermission p : dadas) {
				if (p.getUri().equals(u) && p.isWritePermission()) {
					vale = true;
				}
			}
			if (!vale) {
				return null;
			}
			return nomeDe(c.getContentResolver(), raiz(u)) != null ? u : null;
		} catch (Throwable t) {
			return null;
		}
	}

	private static Uri raiz(Uri arvore) {
		return DocumentsContract.buildDocumentUriUsingTree(arvore, DocumentsContract.getTreeDocumentId(arvore));
	}

	private static String nomeDe(ContentResolver cr, Uri doc) {
		Cursor k = null;
		try {
			k = cr.query(doc, new String[] {DocumentsContract.Document.COLUMN_DISPLAY_NAME}, null, null, null);
			if (k != null && k.moveToFirst()) {
				String n = k.getString(0);
				return n != null ? n : "";
			}
		} catch (Throwable t) {
			// (pendrive fora)
		} finally {
			if (k != null) {
				k.close();
			}
		}
		return null;
	}

	/** O nome da pasta escolhida ("" = não tem, ou o pendrive dela não está espetado). */
	static String nome(Context c) {
		try {
			Uri u = pasta(c);
			if (u == null) {
				return "";
			}
			String n = nomeDe(c.getContentResolver(), raiz(u));
			return n == null || n.length() == 0 ? "pendrive" : n;
		} catch (Throwable t) {
			return "";
		}
	}

	private static Uri achar(ContentResolver cr, Uri arvore, Uri pai, String nome) {
		Uri filhos = DocumentsContract.buildChildDocumentsUriUsingTree(arvore, DocumentsContract.getDocumentId(pai));
		Cursor k = null;
		try {
			k = cr.query(filhos, new String[] {DocumentsContract.Document.COLUMN_DOCUMENT_ID,
					DocumentsContract.Document.COLUMN_DISPLAY_NAME}, null, null, null);
			while (k != null && k.moveToNext()) {
				if (nome.equalsIgnoreCase(k.getString(1))) {
					return DocumentsContract.buildDocumentUriUsingTree(arvore, k.getString(0));
				}
			}
		} finally {
			if (k != null) {
				k.close();
			}
		}
		return null;
	}

	private static String tipoDe(String nome) {
		int p = nome.lastIndexOf('.');
		String tipo = p >= 0 ? MimeTypeMap.getSingleton().getMimeTypeFromExtension(nome.substring(p + 1).toLowerCase()) : null;
		return tipo != null ? tipo : "application/octet-stream";
	}

	/** Anda por "pasta/sub/arquivo.csv" dentro da pasta escolhida (criando o que faltar, se pedido). */
	private static Uri caminho(ContentResolver cr, Uri arvore, String rel, boolean criar) throws Exception {
		Uri atual = raiz(arvore);
		String[] partes = rel.split("/");
		for (int i = 0; i < partes.length; i++) {
			String n = partes[i];
			if (n.length() == 0) {
				continue;
			}
			Uri f = achar(cr, arvore, atual, n);
			if (f == null) {
				if (!criar) {
					return null;
				}
				boolean ultimo = i == partes.length - 1;
				f = DocumentsContract.createDocument(cr, atual, ultimo ? tipoDe(n) : DocumentsContract.Document.MIME_TYPE_DIR, n);
				if (f == null) {
					return null;
				}
				// (o Android às vezes muda o nome que criou, ex. "x.csv.txt")
				String ficou = nomeDe(cr, f);
				if (ficou != null && !ficou.equalsIgnoreCase(n)) {
					try {
						Uri certo = DocumentsContract.renameDocument(cr, f, n);
						if (certo != null) {
							f = certo;
						}
					} catch (Throwable t) {
						Log.w(TAG, "pendrive: ficou com o nome " + ficou);
					}
				}
			}
			atual = f;
		}
		return atual;
	}

	/** O texto do arquivo (UTF-8) dentro da pasta escolhida; "" se não existe. */
	static String ler(Context c, String rel) {
		InputStream in = null;
		try {
			Uri arvore = pasta(c);
			if (arvore == null) {
				return "";
			}
			ContentResolver cr = c.getContentResolver();
			Uri doc = caminho(cr, arvore, rel, false);
			if (doc == null) {
				return "";
			}
			in = cr.openInputStream(doc);
			if (in == null) {
				return "";
			}
			ByteArrayOutputStream tudo = new ByteArrayOutputStream();
			byte[] b = new byte[16384];
			int n;
			while ((n = in.read(b)) > 0 && tudo.size() < LIMITE) {
				tudo.write(b, 0, n);
			}
			return new String(tudo.toByteArray(), UTF8);
		} catch (Throwable t) {
			Log.w(TAG, "pendrive: ler " + rel + ": " + t);
			return "";
		} finally {
			if (in != null) {
				try {
					in.close();
				} catch (Throwable t) {
					// nada
				}
			}
		}
	}

	/** Grava o arquivo inteiro (UTF-8) e manda para o pendrive de verdade (sync). */
	static boolean gravar(Context c, String rel, String texto) {
		ParcelFileDescriptor pfd = null;
		FileOutputStream out = null;
		try {
			Uri arvore = pasta(c);
			if (arvore == null) {
				return false;
			}
			ContentResolver cr = c.getContentResolver();
			Uri doc = caminho(cr, arvore, rel, true);
			if (doc == null) {
				return false;
			}
			try {
				pfd = cr.openFileDescriptor(doc, "wt");
			} catch (Throwable t) {
				pfd = cr.openFileDescriptor(doc, "w");
			}
			if (pfd == null) {
				return false;
			}
			out = new FileOutputStream(pfd.getFileDescriptor());
			out.write(texto.getBytes(UTF8));
			out.flush();
			try {
				out.getFD().sync();
			} catch (Throwable t) {
				// (o Android manda mais tarde)
			}
			return true;
		} catch (Throwable t) {
			Log.w(TAG, "pendrive: gravar " + rel + ": " + t);
			return false;
		} finally {
			try {
				if (out != null) {
					out.close();
				}
				if (pfd != null) {
					pfd.close();
				}
			} catch (Throwable t) {
				// nada
			}
		}
	}

	/** Manda tudo que o Android ainda guarda na memória para os discos (antes de tirar o pendrive). */
	static void sincronizar() {
		try {
			final Process p = Runtime.getRuntime().exec(new String[] {"sync"});
			Thread t = new Thread(new Runnable() {
				@Override
				public void run() {
					try {
						p.waitFor();
					} catch (Throwable e) {
						// nada
					}
				}
			});
			t.start();
			t.join(4000);
		} catch (Throwable t) {
			// (sem o comando: o Android grava sozinho em alguns segundos)
		}
	}
}
