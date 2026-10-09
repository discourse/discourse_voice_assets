// Bundled into public/javascripts/stt/vad.<hash>.js and dynamic-import()ed
// by lib/resenha/subtitles.js — plugins can't import npm modules directly,
// and the VAD (with its own onnxruntime-web) is only worth downloading once
// subtitles are actually enabled.
// Deep import: the package index also pulls in NonRealTimeVAD and with it
// the full (JSEP) onnxruntime-web build; MicVAD only needs the wasm entry.
export { MicVAD } from "@ricky0123/vad-web/dist/real-time-vad.js";
