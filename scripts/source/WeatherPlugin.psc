ScriptName WeatherPlugin Hidden

; Get version of plugin or 0 if not installed.
Int Function GetVersion() Global Native

; Instantly reset all multipliers, may look weird.
Function Reset() Global Native

; Set global tree value multipliers. Time means it takes this many seconds to reach target values (0 = instant but may look weird, 3 = ok).
; Example: SetTreeValues(3, 1, 1, 3, 2) ; Set tree value multipliers over the next 3 seconds.
; trunkFlex - NOT work, game can't change it in real time
; branchFlex - NOT work, same
; leafAmplitude - works, how big movements the leaf makes because of wind, high amplitude is large movement
; leafFrequency - works, how many movements the leaf makes because of wind, high frequency is lots of movement
; 1.0 - tree's own default value whatever that may be (this is multiplier remember)
Function SetTreeValues(float time, float trunkFlex = 1.0, float branchFlex = 1.0, float leafAmplitude = 1.0, float leafFrequency = 1.0) Global Native

; Get target value last set for index.
; 0 - trunkFlex, 1 - branchFlex, 2 - leafAmplitude, 3 - leafFrequency.
Float Function GetTreeValues(int index) Global Native

; Disable precipitation (1) or re-enable it (0).
Function SetPrecipitationDisabled(int disabled) Global Native

; Get current weather precipitation particle gravity velocity. Returns 0 if not valid for some reason.
Float Function GetPrecipitationGravityVelocity() Global Native
