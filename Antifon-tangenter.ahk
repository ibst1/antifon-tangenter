; Antifon-tangenter — v1.0.2
; Kortkommandon för Antifon i hela Windows, på datorn man styr Antifon från (fjärrdrift),
; och ett litet fönster överst med knapparna och läget. Startas från Antifons driftssida
; (knappen ⌨ Tangenter i sidhuvudet), som skickar med adressen och nyckeln.
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
CoordMode("ToolTip", "Screen")

global INI := A_ScriptDir "\Antifon-tangenter.ini"
global cfg := {url: IniRead(INI, "Antifon", "url", ""), token: IniRead(INI, "Antifon", "token", "")}
global state := Map(), bound := Map(), connected := false, lastError := ""
global showWindow := IniRead(INI, "Fönster", "visa", "1") = "1"

OnError(LogError)
RegisterProtocol()

; startad med länken från driftssidan: antifon-tangenter://connect?url=…&token=…
for arg in A_Args {
    if InStr(arg, "antifon-tangenter:") = 1 {
        if RegExMatch(arg, "[?&]url=([^&]+)", &m)
            cfg.url := RTrim(UriDecode(m[1]), "/")
        if RegExMatch(arg, "[?&]token=([^&]+)", &m)
            cfg.token := UriDecode(m[1])
        IniWrite(cfg.url, INI, "Antifon", "url")
        IniWrite(cfg.token, INI, "Antifon", "token")
    }
}
if cfg.url = "" || cfg.token = "" {
    MsgBox("Antifon-tangenter är nu installerat på den här datorn.`n`n"
         . "Gå tillbaka till Antifons driftssida (inloggad med fjärrdriftens lösenord) och tryck "
         . "⌨ Tangenter i sidhuvudet igen – då startar programmet med rätt adress.", "Antifon-tangenter", "Iconi")
    ExitApp
}

; --- fönstret ----------------------------------------------------------------------------------
global g := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox", "Antifon")
g.SetFont("s10", "Segoe UI")
g.MarginX := 10, g.MarginY := 8
global txtStatus := g.AddText("w280 r4", "Ansluter till Antifon …")
global buttons := Map()
for action in ["broadcast", "record", "clip", "remote", "marker"] {
    b := g.AddButton("w280 h30", action)
    b.OnEvent("Click", Press.Bind(action))
    buttons[action] := b
}
g.OnEvent("Close", (*) => SetWindow(false))

A_IconTip := "Antifon-tangenter"
tray := A_TrayMenu
tray.Delete()
tray.Add("Visa fönstret med knapparna", (*) => SetWindow(!showWindow))
tray.Add("Öppna driftssidan", (*) => Run(cfg.url "/admin"))
tray.Add()
tray.Add("Avsluta", (*) => ExitApp())
tray.Default := "Visa fönstret med knapparna"

Poll()
SetTimer(Poll, 2000)
SetWindow(showWindow)
return

SetWindow(on) {
    global showWindow
    showWindow := on
    IniWrite(on ? "1" : "0", INI, "Fönster", "visa")
    if on {
        x := IniRead(INI, "Fönster", "x", ""), y := IniRead(INI, "Fönster", "y", "")
        g.Show((x != "" ? "x" x " y" y " " : "") "AutoSize NoActivate")
        A_TrayMenu.Check("Visa fönstret med knapparna")
    } else {
        try {
            g.GetPos(&x, &y)
            IniWrite(x, INI, "Fönster", "x"), IniWrite(y, INI, "Fönster", "y")
        }
        g.Hide()
        A_TrayMenu.Uncheck("Visa fönstret med knapparna")
    }
}

; --- Antifon: läget och kortkommandona ----------------------------------------------------------
Poll(*) {
    global state, connected, lastError
    try {
        text := Http("GET", "/api/mini")
        s := Map()
        for line in StrSplit(text, "`n", "`r") {
            if (p := InStr(line, "="))
                s[SubStr(line, 1, p - 1)] := SubStr(line, p + 1)
        }
        if !connected
            Log("ansluten till " cfg.url " (Antifon " s.Get("version", "?") ")")
        state := s, connected := true, lastError := ""
        BindHotkeys()
    } catch as e {
        if connected || lastError != e.Message
            Log("ingen kontakt: " e.Message)
        connected := false, lastError := e.Message
    }
    Render()
}

BindHotkeys() {
    global bound
    for action in ["broadcast", "record", "clip", "remote", "marker"] {
        spec := ToAhk(state.Get("hk_" action, ""))
        if bound.Has(action) && bound[action] = spec
            continue
        if bound.Has(action) && bound[action] != ""
            try Hotkey(bound[action], "Off")
        bound[action] := spec
        if spec != "" {
            try {
                Hotkey(spec, Press.Bind(action), "On")
                Log("kortkommando " Pretty(state.Get("hk_" action, "")) " → " action)
            } catch as e {
                Log("kortkommandot " spec " gick inte att använda: " e.Message)
            }
        }
    }
}

Render() {
    on := (k) => state.Get(k, "0") = "1"
    linkedAir := on("link_air_record"), linkedClip := on("link_clip_remote")
    both := on("on_air") && on("recording")
    if !connected {
        txtStatus.Value := "Ingen kontakt med Antifon`n" cfg.url "`n" lastError
    } else {
        l1 := linkedAir ? "Läge 1: " (both ? "PÅ · spelar in " Clock(state.Get("rec_seconds", 0)) : "av")
                        : "Tolkning: " (on("on_air") ? "på" : "av") " · inspelning 1: " (on("recording") ? Clock(state.Get("rec_seconds", 0)) : "av")
        l2 := (linkedClip ? "Läge 2: " : "Inspelning 2: ") (on("clip") ? "PÅ · " Clock(state.Get("clip_seconds", 0)) : "av")
        l3 := linkedClip ? "" : "Distans: " (on("remote_on") ? "öppen" : "stängd") " · "
        txtStatus.Value := l1 "`n" l2 "`n" l3 state.Get("listeners", "0") " lyssnare"
    }
    Label("broadcast", (linkedAir ? (both ? "■ Stoppa" : "▶ Starta") " läge 1"
                                  : (on("on_air") ? "■ Stäng av" : "▶ Slå på") " tolkningen"), true)
    Label("record", (on("recording") ? "■ Stoppa" : "▶ Starta") " inspelning 1", !linkedAir)
    Label("clip", (on("clip") ? "■ Stoppa " : "▶ Starta ") (linkedClip ? "läge 2" : "inspelning 2"), true)
    Label("remote", (on("remote_on") ? "■ Stäng" : "▶ Öppna") " distans", !linkedClip)
    Label("marker", "◆ Markering", true)
    ; knapparna som syns, i ordning under statusraden
    txtStatus.GetPos(, &y, , &h)
    y += h + 6
    for action in ["broadcast", "record", "clip", "remote", "marker"] {
        b := buttons[action]
        if b.Visible {
            b.Move(, y)
            y += 34
        }
    }
    if showWindow
        g.Show("AutoSize NoActivate")
}

Label(action, text, visible) {
    hk := Pretty(state.Get("hk_" action, ""))
    b := buttons[action]
    b.Text := text (hk != "" ? "     " hk : "")
    b.Visible := visible
    b.Enabled := connected
}

Press(action, *) {
    try {
        Http("POST", "/api/hotkey", '{"action":"' action '"}')
        Poll()
        on := (k) => state.Get(k, "0") = "1"
        msg := action = "broadcast" ? (state.Get("link_air_record") = "1" ? "Läge 1 " (on("on_air") && on("recording") ? "på" : "av")
                                                                       : "Tolkning " (on("on_air") ? "på" : "av"))
             : action = "record" ? "Inspelning 1 " (on("recording") ? "på" : "av")
             : action = "clip" ? (state.Get("link_clip_remote") = "1" ? "Läge 2 " : "Inspelning 2 ") (on("clip") ? "på" : "av")
             : action = "remote" ? "Distans " (on("remote_on") ? "öppen" : "stängd")
             : "Markering satt"
        Notify(msg)
    } catch as e {
        Notify("Kortkommandot gick inte fram: " e.Message)
    }
}

Notify(text) {
    ToolTip(text, A_ScreenWidth // 2 - 80, 40)
    SetTimer(() => ToolTip(), -1800)
}

; --- hjälpfunktioner ----------------------------------------------------------------------------
Http(method, path, body := "") {
    req := ComObject("WinHttp.WinHttpRequest.5.1")
    req.Open(method, cfg.url path, false)
    req.SetTimeouts(3000, 3000, 5000, 5000)
    req.SetRequestHeader("X-Antifon-Token", cfg.token)
    if body != ""
        req.SetRequestHeader("Content-Type", "application/json")
    req.Send(body)
    if req.Status = 403
        throw Error("fel nyckel – starta igen från driftssidan")
    if req.Status != 200
        throw Error("HTTP " req.Status)
    return req.ResponseText
}

ToAhk(spec) {
    ; "ctrl+shift+f9" -> "^+f9"
    if spec = ""
        return ""
    parts := StrSplit(StrLower(spec), "+")
    key := parts.Pop()
    mods := ""
    for p in parts
        mods .= p = "ctrl" ? "^" : p = "shift" ? "+" : p = "alt" ? "!" : p = "win" ? "#" : ""
    return mods key
}

Pretty(spec) {
    out := ""
    for p in StrSplit(spec, "+")
        out .= (out = "" ? "" : "+") (StrLen(p) > 1 && !RegExMatch(p, "i)^f\d+$") ? StrUpper(SubStr(p, 1, 1)) SubStr(p, 2) : StrUpper(p))
    return out
}

Clock(seconds) {
    s := Integer(seconds)
    return s >= 3600 ? Format("{}:{:02}:{:02}", s // 3600, Mod(s // 60, 60), Mod(s, 60)) : Format("{}:{:02}", s // 60, Mod(s, 60))
}

UriDecode(str) {
    out := "", i := 1
    buf := Buffer(StrLen(str))
    n := 0
    while i <= StrLen(str) {
        c := SubStr(str, i, 1)
        if c = "%" && i + 2 <= StrLen(str) {
            NumPut("UChar", Integer("0x" SubStr(str, i + 1, 2)), buf, n++)
            i += 3
        } else {
            NumPut("UChar", Ord(c = "+" ? " " : c), buf, n++)
            i += 1
        }
    }
    return StrGet(buf, n, "UTF-8")
}

RegisterProtocol() {
    ; länken antifon-tangenter://… från driftssidan startar det här programmet
    key := "HKCU\Software\Classes\antifon-tangenter"
    cmd := '"' A_AhkPath '" "' A_ScriptFullPath '" "%1"'
    try {
        if RegRead(key "\shell\open\command") = cmd
            return
    }
    RegWrite("URL:Antifon-tangenter", "REG_SZ", key)
    RegWrite("", "REG_SZ", key, "URL Protocol")
    RegWrite(cmd, "REG_SZ", key "\shell\open\command")
}

; --- logg: Antifon-tangenter.log bredvid programmet (de senaste raderna) --------------------------
Log(text) {
    path := A_ScriptDir "\Antifon-tangenter.log"
    try {
        if FileExist(path) && FileGetSize(path) > 100000
            FileMove(path, path ".old", true)
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " text "`n", path, "UTF-8")
    }
}

LogError(e, mode) {
    Log("fel: " e.Message " (" e.What ", rad " e.Line ")")
    return mode = "Return" ? -1 : 1
}
