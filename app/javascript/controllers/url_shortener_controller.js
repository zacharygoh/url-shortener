// app/javascript/controllers/url_shortener_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input",
    "submitBtn",
    "result",
    "shortUrl",
    "targetUrl",
    "title",
    "titleDisplay",
    "error"
  ]

  async shorten(event) {
    event.preventDefault()

    const targetUrl = this.inputTarget.value.trim()

    if (!targetUrl) {
      this.showError("Please enter a URL")
      return
    }

    // Disable button and show loading state
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = "Shortening..."

    try {
      const response = await fetch("/api/shorten", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: JSON.stringify({ target_url: targetUrl })
      })

      const data = await response.json()

      if (response.ok) {
        this.showSuccess(data.data)
      } else {
        this.showError(data.errors ? data.errors.join(", ") : "Failed to create short URL")
      }
    } catch (error) {
      console.error("Error:", error)
      this.showError("Network error. Please try again.")
    } finally {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.textContent = "Shorten"
    }
  }

  showSuccess(data) {
    this.errorTarget.classList.add("hidden")
    this.resultTarget.classList.remove("hidden")

    this.shortUrlTarget.value = data.short_url

    this.targetUrlTarget.href = data.target_url
    this.targetUrlTarget.textContent = data.target_url

    if (data.title) {
      this.titleTarget.textContent = data.title
      this.titleDisplayTarget.classList.remove("hidden")
    } else {
      this.titleDisplayTarget.classList.add("hidden")
    }

    // Scroll to result
    this.resultTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
  }

  showError(message) {
    this.resultTarget.classList.add("hidden")
    this.errorTarget.classList.remove("hidden")
    this.errorTarget.textContent = message
  }

  copy(event) {
    event.preventDefault()

    const button = event.currentTarget
    const originalText = button.textContent
    const text = this.shortUrlTarget.value

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

    const copyFailed = () => {
      this.showError("Failed to copy to clipboard")
    }

    this.shortUrlTarget.select()
    this.shortUrlTarget.setSelectionRange(0, 99999)

    if (navigator.clipboard && typeof navigator.clipboard.writeText === "function") {
      navigator.clipboard.writeText(text).then(showCopied).catch(() => {
        if (this.execCommandCopy()) showCopied()
        else copyFailed()
      })
    } else {
      if (this.execCommandCopy()) showCopied()
      else copyFailed()
    }
  }

  execCommandCopy() {
    try {
      return document.execCommand("copy")
    } catch {
      return false
    }
  }
}
