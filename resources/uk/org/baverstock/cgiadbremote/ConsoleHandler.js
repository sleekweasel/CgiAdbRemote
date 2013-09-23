document.dragstart = function() { return false; }
function renewAutoScreen() {
    document.refreshScreenAfter = document.param_touchdelay;
    document.refreshNum = document.param_refreshNum;
}
renewAutoScreen();
function url(rest) {
    here = window.location.href.split("/");
    here.pop();
    here.push(rest);
    return here.join("/");
}
function getScale() {
    return document.autoScale;
}
function mouseDown(i, e) {
    document.firstDown = e;
    document.lastStamp = e.timeStamp;
    mousePut(i, e, 'down');
    renewAutoScreen();
    return true;
}
function mouseMove(i, e) {
    if (document.lastStamp > 0 && e.timeStamp > document.lastStamp + 100) {
        mousePut(i, e, 'move');
        renewAutoScreen();
    }
    return true;
}
function mousePut(i, e, what) {
    document.lastStamp = e.timeStamp;
    xoff = i.x - window.pageXOffset;
    yoff = i.y - window.pageYOffset;

    s = getScale();
    x1 = Math.round((e.clientX-xoff)/s);
    y1 = Math.round((e.clientY-yoff)/s);

    ih = Math.round(i.height);
    iw = Math.round(i.width);

    touch = "touch?device=" + document.param_serialNumber +
        "&deg=" + qParam("deg", "0") +
        "&"+what+"=?" + x1 + "," + y1 +
        "&img=?" + iw + "," + ih;
    window.frames["stdout"].location=url(touch);
    return true;
}
function mouseUp(i, e) {
    document.lastStamp = 0;
    f=document.firstDown;
    delete document.firstDown;
    if (typeof f === 'undefined') {
        return;
    }
    xoff = i.x - window.pageXOffset;
    yoff = i.y - window.pageYOffset;

    s = getScale();
    x1 = Math.round((f.clientX-xoff)/s);
    y1 = Math.round((f.clientY-yoff)/s);

    x2 = Math.round((e.x-xoff)/s);
    y2 = Math.round((e.y-yoff)/s);

    ih = Math.round(i.height);
    iw = Math.round(i.width);

    touch = "touch?device=" + document.param_serialNumber +
        "&deg=" + qParam("deg", "0") +
        "&down=?" + x1 + "," + y1 +
        "&up=?" + x2 + "," + y2 +
        "&img=?" + iw + "," + ih;
    window.frames["stdout"].location=url(touch);

    renewAutoScreen();
    return true;
}
function keyPress(i, e) {
    // Try to handle keypress and keydown together: assume charCode=0 if press.
    if (e.keyCode == 8) {
        keyEvent(i, 67);
    }
    else if (e.charCode == 0) {
        return;
    }
    else if (e.charCode == 32) {
        keyEvent(i, 62);
    }
    else {
        window.frames["stdout"].location=url(
            "text?device="+document.param_serialNumber+"&text="+String.fromCharCode(e.charCode));
    }
    renewAutoScreen();
    return true;
}
function keyEvent(i, e) {
    window.frames["stdout"].location=url("text?device="+document.param_serialNumber+"&key="+e);
    renewAutoScreen();
    return true;
}
function onAdb() {
    cmd = document.getElementById("adbcmd").value;
    document.getElementById("adbcmd").value = '';
    window.frames["stdout"].location=url("adbCmd?device="+document.param_serialNumber+"&cmd="+cmd);
    return true;
}
function qParam(k, d) {
    qPairs = window.location.hash.split("#");
    while (qPairs.length) {
        pair = qPairs.shift();
        kv = pair.split("=");
        if (kv[0] == k) return kv[1];
    }
    return d;
}
function qHash() {
    qPairs = window.location.hash.split("#");
    hash = {};
    while (qPairs.length) {
        pair = qPairs.shift();
        kv = pair.split("=");
        hash[kv[0]] = kv[1];
    }
    return hash;
}
function updateHash(k, v) {
    hash = qHash();
    hash[k]=v;
    s = '';
    for (key in hash) {
        if (key!==undefined && key != 'undefined' && hash[key]!==undefined && hash[key] != 'undefined' ) {
            s += '#' + key + '=' + hash[key];
        }
    }
    window.location.hash = s;
}
function maybeRotate(image) {
    image = document.getElementById("screen");
    w = (image.width);
    h = (image.height);
    deg = qParam('deg', '0');
    autoScale = qParam("autoScale", "false");
    document.autoScale = 1;
    if (autoScale == "true") {
        br = document.getElementById("bottomright");
        hh = br.offsetTop;
        ww = br.offsetLeft;
        switch (deg) {
            case '90': case '270':
            t = hh; hh = ww; ww = t;
        }
        document.autoScale = Math.min(ww/w, hh/h) * 0.9;
    }
    s = getScale();
    switch (deg) {
        case "0":
        transform =
            ''
            + 'scale(' + s + ') '
            + 'translate('+Math.round(w*.5/-s)+'px,'+Math.round(h*.5/-s)+'px) '
            + 'translate('+Math.round(w/2)+'px,'+Math.round(h/2)+'px) '
            ;
        break;
        case "90":
        transform =
            ''
            + 'scale(' + s + ') '
            + 'rotate(90deg)'
            + 'translate('+Math.round(-h*.5/s)+'px,'+Math.round(w*.5/s)+'px) '
            + 'translate('+Math.round(w/2)+'px,'+Math.round(-h/2)+'px) '
            ;
        break;
        case "180":
        transform =
            ''
            + 'scale(' + s + ') '
            + 'rotate(180deg)'
            + 'translate('+Math.round(w*.5/s)+'px,'+Math.round(h*.5/s)+'px) '
            + 'translate('+Math.round(-w/2)+'px,'+Math.round(-h/2)+'px) '
            ;
        break;
        case "270":
        transform =
            ''
            + 'scale(' + s + ') '
            + 'rotate(270deg) '
            + 'translate('+Math.round(h*.5/s)+'px,'+Math.round(-w*.5/s)+'px) '
            + 'translate('+Math.round(-w/2)+'px,'+Math.round(h/2)+'px) '
            ;
        break;
    }
    image.style.webkitTransform = transform;
    b = document.getElementById("d"+deg+'deg');
    if (b != null) {
        b.style.backgroundColor='red';
        b.style.color='white';
    }
}
function everyHalfSecond() {
    if (document.refreshNum != 0) {
        bar = '';
        for (i=0; i<document.refreshScreenAfter; i++) {
            bar += '*';
        }
        refresh = "Screen refresh (" + document.refreshNum + ") in: " + bar;
        document.title=refresh;
    }
    else {
        refresh = "<span style='color: red'>Auto refresh paused until user activity</span>";
    }
    document.getElementById('refreshAfter').innerHTML = refresh;
    document.getElementById('showscale').innerHTML = ("" + getScale()).substr(0,5);
    if (document.refreshScreenAfter > 0 && document.refreshNum != 0) {
        document.refreshScreenAfter = document.refreshScreenAfter - 1;
        if (document.refreshScreenAfter <= 0) {
            document.refreshNum = document.refreshNum - 1;
            screen = document.getElementById("screen");
            screen.style.borderColor='red';
            screen.src = screen.src.split("#")[0] + "#" + new Date();
        }
    }
}
function onLoadScreen(image) {
    image.style.borderColor='grey';
    maybeRotate(image);
    document.refreshScreenAfter = document.param_idledelay;
}
function logResponse(doc) {
    if (doc.logger != null) {
        logg = doc.logger.frameElement.contentDocument;
        logg.body.innerHTML = logg.body.innerHTML +
            "<pre>" +
            doc.stdout.frameElement.contentDocument.body.innerHTML +
            "</pre>";
        logg.body.scrollTop = logg.height;
    }
    renewAutoScreen()
}

setInterval(everyHalfSecond, 500);
