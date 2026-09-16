# Cards Memory

App em Flutter para criar e praticar flashcards (cartões de memória) —
pensado originalmente para estudar Libras, mas serve para memorizar
qualquer coisa: vocabulário de idiomas, conceitos, o que for.

Roda em Android, iOS e desktop (Windows/macOS/Linux) a partir da mesma
base de código. Tudo é salvo localmente no dispositivo (SQLite via
`sqflite`/`sqflite_common_ffi`) — sem backend, sem conta, sem nuvem.

## Funcionalidades

- **Bibliotecas**: organize os cartões em categorias (ex: "Libras",
  "Inglês", "Japonês"), cada uma com rótulos de frente/verso
  configuráveis (ex: "Sinal" / "Significado", "Inglês" / "Português").
- **Cartões com foto**: cada cartão tem um texto na frente e no verso,
  cada lado podendo ter uma foto opcional (ex: a foto do sinal em Libras).
- **Prática guiada**: sessões de 10 a 20 palavras, com flip animado e
  botões "Acertei" / "Errei".
- **Priorização inteligente**: a cada sessão, o app prioriza as palavras
  menos praticadas e as que você mais erra, combinando taxa de erro e
  número de repetições já feitas.
- **Estatísticas por cartão**: quantas vezes foi praticado e a taxa de
  erro, visíveis na lista de cada biblioteca.
- **Tema claro/escuro** automático, seguindo o sistema.

## Rodando o projeto

```
flutter pub get
flutter run
```

Para gerar um APK de release:

```
flutter build apk --release
```

O arquivo sai em `build/app/outputs/flutter-apk/app-release.apk`.
