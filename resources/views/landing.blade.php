<!DOCTYPE html>
<html data-theme="{{ $defaultPreferences['theme'] }}" lang="{{ $lang }}">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="description" content="{{ __('message.2fauth_description') }}" lang="{{ $lang }}">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0, shrink-to-fit=no, viewport-fit=cover">
    <meta name="csrf-token" content="{{csrf_token()}}">
    <meta name="robots" content="noindex, nofollow">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <title>{{ config('app.name') }}</title>

    <link rel="shortcut icon" href="{{ asset('favicon.ico') }}" />
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}" />
    <link rel="apple-touch-icon" href="{{ asset('favicon_lg.png') }}" />
    <link rel="apple-touch-icon-precomposed" href="{{ asset('favicon_lg.png') }}" />
    <link rel="manifest" href="{{ asset('manifest.json') }}">
    <meta name="theme-color" content="#fffbfe" media="(prefers-color-scheme: light)">
    <meta name="theme-color" content="#141218" media="(prefers-color-scheme: dark)">
    <script type="text/javascript" {!! isset($cspNonce) ? "nonce='" . $cspNonce . "'" : "" !!}>
        // Apply the colour scheme before first paint (same storage key as VueUse's useColorMode).
        (function () {
            try {
                var mode = localStorage.getItem('vueuse-color-scheme') || '{{ $defaultPreferences['theme'] == 'system' ? 'auto' : $defaultPreferences['theme'] }}';
                var dark = mode === 'dark' || (mode !== 'light' && window.matchMedia('(prefers-color-scheme: dark)').matches);
                document.documentElement.classList.toggle('dark', dark);
            } catch (e) {}
        })();
    </script>

</head>
<body>
    <div id="app">
        <app></app>
    </div>
    <script type="text/javascript"
        {!! isset($cspNonce) ? "nonce='" . $cspNonce . "'" : "" !!} >
        var appSettings = {!! $appSettings !!};
        var appConfig = {!! $appConfig !!};
        var urls = {!! $urls !!};
        var defaultPreferences = {!! $defaultPreferences->toJson() !!};
        var lockedPreferences = {!! $lockedPreferences->toJson() !!};
        var appVersion = '{{ config("2fauth.version") }}';
        var isDemoApp = {!! $isDemoApp !!};
        var isTestingApp = {!! $isTestingApp !!};
        var appLocales = {!! $locales !!};
    </script>
    @vite('resources/js/app.js')
</body>
</html>