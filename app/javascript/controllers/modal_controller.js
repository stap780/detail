import { Controller } from "@hotwired/stimulus"
import { StreamActions } from "@hotwired/turbo"
import { Modal } from "bootstrap"

// Connects to data-controller="modal"
export default class extends Controller {

  connect() {
    //console.log("modal work");
    this.modal = new bootstrap.Modal(this.element)
    // this.modal.show()
  }


  // это вариант с сайт (более классический) https://www.hotrails.dev/articles/rails-modals-with-hotwire
  open() {
    if (!this.modal.isOpened) {
      this.modal.show()
    }
  }

  close(event) {
    if (event.detail.success) {
      this.modal.hide()
    }
  }
  // конец 

}

StreamActions.set_unchecked = function() {
  // console.log('elements length => ', this.targetElements.length )
  this.targetElements.forEach((element) => {
    element.checked = false
    // console.log('element set_unchecked => ', element)
  });
}
StreamActions.open_modal = function() {
  // console.log('elements length => ', this.targetElements.length )
  this.targetElements.forEach((element) => {
    // console.log('element open_modal => ', element)
    const modal = new bootstrap.Modal(element)
    modal.show()
  });
}