import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="selectall"
export default class extends Controller {
  static targets = ["checkboxAll", "checkbox"]
  connect() {
    console.log('SelectAll checkbox Do what you want here.')
    // set all to false on page refresh
    this.checkboxTargets.map(x => x.checked = false)
    this.checkboxAllTarget.checked = false

  }

  toggleChildren() {
    if (this.checkboxAllTarget.checked) {
      this.checkboxTargets.map(x => x.checked = true)
    } else {
      this.checkboxTargets.map(x => x.checked = false)
    }
  }

  toggleParent() {
    if (this.checkboxTargets.map(x => x.checked).includes(false)) {
      this.checkboxAllTarget.checked = false
    } else {
      this.checkboxAllTarget.checked = true
    }
  }
  
}

