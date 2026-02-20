// app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

// Copies a value (e.g. short URL) to clipboard and shows "Copied!" feedback.
// Use with data-clipboard-text-value="<url>" on the element that triggers copy.
export default class extends Controller {
  static values = { text: String }

  copy(event) {
    event.preventDefault()
    const button = event.currentTarget
    const originalText = button.textContent
    const text = this.textValue

    const showCopied = () => {
      button.textContent = "Copied!"
      button.classList.add("bg-green-600", "hover:bg-green-700")
      button.classList.remove("bg-indigo-600", "hover:bg-indigo-700")
      setTimeout(() => {
        button.textContent = originalText
        button.classList.remove("bg-green-600", "hover:bg-green-700")
        button.classList.add("bg-indigo-600", "hover:bg-indigo-700")
      }, 2000)
    }

    if (navigator.clipboard?.writeText) {
      navigator.clipboard.writeText(text).then(showCopied).catch(() => {
        if (this.execCommandCopy(text)) showCopied()
      })
    } else {
      if (this.execCommandCopy(text)) showCopied()
    }
  }

  execCommandCopy(text) {
    try {
      const el = document.createElement("textarea")
      el.value = text
      el.setAttribute("readonly", "")
      el.style.position = "absolute"
      el.style.left = "-9999px"
      document.body.appendChild(el)
      el.select()
      const ok = document.execCommand("copy")
      document.body.removeChild(el)
      return ok
    } catch {
      return false
    }
  }
}
