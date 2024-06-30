import { Controller } from "@hotwired/stimulus"
import { Alert } from "bootstrap"

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
    // console.log("alert work");
    this.alert = new Alert(this.element)
    setTimeout(() => {
      this.alert.close();
    }, 5000);
  }
}