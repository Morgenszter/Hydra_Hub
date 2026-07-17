# Voice provider contract

A speech-to-text provider receives a VoiceTranscriptionRequest and returns a
Result containing VoiceTranscription.

A text-to-speech provider receives a VoiceSynthesisRequest and returns a Result
containing an AudioStream.

Provider adapters remain replaceable and must not be referenced directly by
presentation classes.