# Vendored 2FAuth components

These packages were copied from [Bubka/2FAuth-Components](https://github.com/Bubka/2FAuth-Components)
(AGPL-3.0, commit `ac9d4e6`) so the front end builds from this repository alone,
and then restyled for the Material You redesign.

| Package               | Import as              | Contents                                         |
| --------------------- | ---------------------- | ------------------------------------------------ |
| `ui/src`              | `@2fauth/ui`           | Layout, modal, footer, OTP display, chips, tabs… |
| `formcontrols/src`    | `@2fauth/formcontrols` | Buttons and form fields                          |
| `stores/src`          | `@2fauth/stores`       | Shared Pinia error-handler store                 |

The `@2fauth/*` names are Vite aliases (see `vite.config.js`), so imports in the
app did not change. The former `@2fauth/styles` package (Bulma + SCSS) has been
replaced by the Tailwind design tokens in `resources/css/app.css`.

Not carried over: the Histoire stories, Vitest specs and the components the web
app never imported (`TwoFAccountList`, `TwoFAccountListItem`, the duplicate
`QrContentDisplay`).
