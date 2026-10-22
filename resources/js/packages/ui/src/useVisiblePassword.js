import { toValue } from 'vue'

export function useVisiblePassword(rawPassword, formatPassword, formatPasswordBy, showOtpAsDot, discloseDottedPwd) {
    if (! rawPassword) {
        rawPassword = ''
    }

    var visiblePassword = String(toValue(rawPassword))

    const groupDigits = () => {
        const _formatPasswordBy = toValue(formatPasswordBy)

        if (visiblePassword.length > 0) {
            const x = Math.ceil(_formatPasswordBy < 1
                ? visiblePassword.length * _formatPasswordBy
                : _formatPasswordBy)

            const chunks = visiblePassword.match(new RegExp(`.{1,${x}}`, 'g'))

            if (chunks) {
                visiblePassword = chunks.join(' ')
            }
        }
    }

    const asDots = () => {
        if (visiblePassword.length > 0 && ! toValue(discloseDottedPwd)) {
            visiblePassword = visiblePassword.replace(/[0-9]/g, '●')
        }
    }

    if (toValue(formatPassword) == true)
        groupDigits()

    if (toValue(showOtpAsDot))
        asDots()

    return visiblePassword
}