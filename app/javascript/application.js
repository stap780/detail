// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"

window.bootstrap = bootstrap;



// $(document).ready(function() {

//   $(".alert").delay(4000).slideUp(200, function() {
//     $(this).alert('close');
//   });

//   $('#edit_multiple').click(function() {
//     //console.log('click');
//     $('.modal').modal('hide');
//     $('#modal-edit').modal('show');
//   });





//   $('#selectAll').click(function() {
//     if (this.checked) {
//       $(':checkbox').each(function() {
//         this.checked = true;
//       });
//     } else {
//       $(':checkbox').each(function() {
//         this.checked = false;
//       });
//     }
//   });

//   $("#edit_multiple").click(function(event) {
//     // event.preventDefault();
//     var checked_pr_array = [];
//     $('#products_table :checked').each(function() {
//       checked_pr_array.push($(this).val());
//     });
//     var url = $(this).attr('href');
//     $.ajax({
//       url: url,
//       data: {
//         product_ids: checked_pr_array
//       },
//       type: "GET",
//       success: function(response) {
//         //console.log(response)
//       },
//       error: function(xhr, textStatus, errorThrown) {}
//     });
//   });

//   $('#deleteAll').click(function() {
//     // event.preventDefault();
//     var array = [];
//     $('#products_table :checked').each(function() {
//       array.push($(this).val());
//     });

//     $.ajax({
//       type: "POST",
//       url: $(this).attr('href') + '.json',
//       data: {
//         ids: array
//       },
//       beforeSend: function() {
//         return confirm("Вы уверенны?");
//       },
//       success: function(data, textStatus, jqXHR) {
//         if (data.status === 'ok') {
//           //alert(data.message);
//           location.reload();
//         }
//       },
//       error: function(jqXHR, textStatus, errorThrown) {
//         console.log(jqXHR);
//       }
//     })

//   });



// });