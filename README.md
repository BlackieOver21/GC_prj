# Projekt na Podstawy tworzenia aplikacji w oparciu o usługi Google Cloud (Sabre Academy)
### Temat: Image Upload + Thumbnail Generator

Działanie aplikacji polega na tym, że użytkownik ma możliwość załadowania obrazu do wiadra Cloud Storage (method unspecified).
Następnie aplikacja uruchamia event, który jest przechwytywany funkcją Cloud Function. Ta funkcja analizuje event (może przeprowadza jakąś walidację obrazka - jak mi się będzie chciało) oraz wysyła wiadomość do message bus-u Pub/Sub. Na podstawie tej wiadomości uruchamiana jest druga funkcja Cloud Function, która generuje miniaturkę tego obrazu.
Koniec działania aplikacji (fascynujące wiem).

<img width="571" height="439" alt="image" src="https://github.com/user-attachments/assets/09cf3791-60e5-4013-a677-a704851aaa70" />

Technologie użyte w projekcie:
- Cloud Storage
- Cloud Functions
- Pub/Sub
