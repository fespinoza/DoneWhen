# Anonymization dictionary

Edit `DoneWhen/Resources/Anonymization.json` and rebuild the app. It is a bundled JSON object mapping protected text to displayed replacements:

```json
{
    "Fido": "Dog",
    "Living Room": "Room"
}
```

Matching ignores case and requires whole words or phrases. Longer matches take priority; replacements are literal and are not processed again. Blank keys, blank values, and keys differing only by case are invalid. An empty, invalid, or missing dictionary disables the Settings toggle.

The toggle defaults off and persists on this device. Timeline and Events browsing use replacements, including Events search and alphabetical sorting. Editing and creation flows show originals. Stored and synced records are never anonymized. The bundled dictionary is readable from the app bundle; this feature only changes presentation.

⚠️⚠️⚠️ **Warning**
The `DoneWhen/Resources/Anonymization.json` is ignored by git. To compile the app on your machine
