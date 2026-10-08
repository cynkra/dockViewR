// Client-side probe for the dockViewR performance app. Loaded in <head>, so it
// wraps WebSocket before Shiny opens its connection. Everything lands on
// `window.dvPerf`, which bench.R reads through chromote.
(function () {
  const P = (window.dvPerf = {
    since: 0,
    out: [],        // raw client -> server frames
    in: [],         // raw server -> client frames
    longtasks: [],
    values: [],     // shiny:value events (output renders)
    inputs: [],     // shiny:inputchanged events
    idle: [],
    marks: {}
  });

  const now = () => performance.now();

  try {
    new PerformanceObserver((list) => {
      list.getEntries().forEach((e) => {
        P.longtasks.push({ t: e.startTime, dur: e.duration });
      });
    }).observe({ type: 'longtask', buffered: true });
  } catch (e) {
    // longtask is Chromium-only; the rest of the probe still works.
  }

  const NativeWS = window.WebSocket;
  function ProbedWS(url, protocols) {
    const ws = protocols === undefined
      ? new NativeWS(url)
      : new NativeWS(url, protocols);
    ws.addEventListener('message', (e) => {
      if (typeof e.data === 'string') P.in.push({ t: now(), raw: e.data });
    });
    const send = ws.send.bind(ws);
    ws.send = (data) => {
      if (typeof data === 'string') P.out.push({ t: now(), raw: data });
      return send(data);
    };
    return ws;
  }
  ProbedWS.prototype = NativeWS.prototype;
  ['CONNECTING', 'OPEN', 'CLOSING', 'CLOSED'].forEach((k) => {
    ProbedWS[k] = NativeWS[k];
  });
  window.WebSocket = ProbedWS;

  document.addEventListener('DOMContentLoaded', () => {
    $(document).on('shiny:connected', () => { P.marks.connected = now(); });
    $(document).on('shiny:value', (e) => {
      P.values.push({ t: now(), name: e.name });
      if (e.name === 'dock' && P.marks.dockValue === undefined) {
        P.marks.dockValue = now();
      }
    });
    $(document).on('shiny:inputchanged', (e) => {
      P.inputs.push({ t: now(), name: e.name });
      if (e.name === 'dock_initialized' && P.marks.dockInitialized === undefined) {
        P.marks.dockInitialized = now();
      }
      if (e.name === 'dock_state' && P.marks.firstState === undefined) {
        P.marks.firstState = now();
      }
    });
    $(document).on('shiny:idle', () => { P.idle.push(now()); });
  });

  // Strip Shiny's "<id>#..." framing when present; plain JSON otherwise.
  const parse = (raw) => {
    try {
      return JSON.parse(raw.replace(/^[^{[]*/, ''));
    } catch (e) {
      return null;
    }
  };

  const sizeOf = (v) => JSON.stringify(v ?? null).length;

  // Start a scenario: everything before this point is ignored by summary().
  P.reset = () => {
    P.since = now();
    return P.since;
  };

  // Quiet period helper for bench.R: ms since the last frame either way.
  P.quietFor = () => {
    const last = Math.max(
      P.out.length ? P.out[P.out.length - 1].t : 0,
      P.in.length ? P.in[P.in.length - 1].t : 0,
      P.values.length ? P.values[P.values.length - 1].t : 0
    );
    return now() - Math.max(last, P.since);
  };

  P.summary = () => {
    const since = P.since;
    const keep = (x) => x.t >= since;

    const outBy = {};
    let outBytes = 0;
    P.out.filter(keep).forEach((f) => {
      outBytes += f.raw.length;
      const msg = parse(f.raw);
      const data = msg && msg.data;
      if (data && typeof data === 'object') {
        Object.keys(data).forEach((k) => {
          const key = k.replace(/:.*$/, '');
          outBy[key] = outBy[key] || { n: 0, bytes: 0 };
          outBy[key].n += 1;
          outBy[key].bytes += sizeOf(data[k]);
        });
      }
    });

    const inBy = {};
    let inBytes = 0;
    P.in.filter(keep).forEach((f) => {
      inBytes += f.raw.length;
      const msg = parse(f.raw);
      if (!msg) return;
      ['values', 'custom'].forEach((field) => {
        if (!msg[field]) return;
        Object.keys(msg[field]).forEach((k) => {
          const key = field + ':' + k;
          inBy[key] = inBy[key] || { n: 0, bytes: 0 };
          inBy[key].n += 1;
          inBy[key].bytes += sizeOf(msg[field][k]);
        });
      });
    });

    const lt = P.longtasks.filter(keep);
    const values = P.values.filter(keep);
    const renders = {};
    values.forEach((v) => { renders[v.name] = (renders[v.name] || 0) + 1; });

    // shiny:inputchanged fires before Shiny drops a value identical to the last
    // one sent, so this counts every setInputValue call, sent or not.
    const inputCalls = {};
    P.inputs.filter(keep).forEach((x) => {
      inputCalls[x.name] = (inputCalls[x.name] || 0) + 1;
    });

    const last = (xs) => (xs.length ? xs[xs.length - 1].t - since : null);

    return {
      outBytes,
      outFrames: P.out.filter(keep).length,
      outBy,
      inBytes,
      inFrames: P.in.filter(keep).length,
      inBy,
      longtaskCount: lt.length,
      longtaskTotal: lt.reduce((a, x) => a + x.dur, 0),
      longtaskMax: lt.reduce((a, x) => Math.max(a, x.dur), 0),
      blockingTime: lt.reduce((a, x) => a + Math.max(0, x.dur - 50), 0),
      renders,
      renderCount: values.length,
      lastRender: last(values),
      lastOut: last(P.out.filter(keep)),
      inputsChanged: P.inputs.filter(keep).length,
      inputCalls,
      domNodes: document.getElementsByTagName('*').length,
      boundOutputs: document.querySelectorAll('.shiny-bound-output').length,
      boundInputs: document.querySelectorAll('.shiny-bound-input').length,
      heapMB: performance.memory
        ? performance.memory.usedJSHeapSize / 1048576
        : null,
      marks: P.marks
    };
  };
})();
