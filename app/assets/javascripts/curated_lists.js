(function() {
  "use strict";
  window.GOVUK = window.GOVUK || {};
  var $ = window.jQuery;
  var csrfToken = $( 'meta[name="csrf-token"]' ).attr( 'content' );

  GOVUK.curatedLists = {
    init: function() {
      GOVUK.curatedLists.redrawUncategorizedList();
      GOVUK.curatedLists.activateRemoveButtons();
      GOVUK.curatedLists.showEmptyLabels();

      $('#all-list-items tr').draggable({
        connectToSortable: '.drag-and-droppable',
        helper: 'clone',
        placeholder: 'droppable-placeholder'
      });

      $('.drag-and-droppable').sortable({
        connectWith: '.drag-and-droppable',
        items: 'tr.item',
        dropOnEmpty: true,
        placeholder: 'droppable-placeholder',
        update: function(event, _draggable) {
          var $targetList = $(event.target);
          GOVUK.curatedLists.reindexList($targetList);
        }
      });
    },
    reindexList: function($list) {
      var $rows = $list.children(':not(.empty-list)');

      $rows.each(function(domIndex, row) {
        var $row = $(row);

        // The item might have a new list ID.
        $row.data({ 'list-id': $list.data('list-id') });

        var updateURL = $row.data('update-url');

        if (updateURL) {
          GOVUK.curatedLists.updateRow(updateURL, $list, $row, domIndex);
        } else {
          GOVUK.curatedLists.createRow($list, $row, domIndex);
        }
      });

      GOVUK.curatedLists.showEmptyLabels();
      GOVUK.curatedLists.redrawUncategorizedList();
    },
    updateRow: function(updateURL, $list, $row, index) {
      $row.addClass('working');

      $.ajax(updateURL, {
        type: 'PUT',
        data: JSON.stringify({
          new_list_id: $list.data('list-id'),
          index: index
        }),
        contentType: 'application/json',
        dataType: 'json',
        headers: { 'X-CSRF-Token': csrfToken },
        success: function() {
          $row.removeClass('working');
          GOVUK.publishing.unlockPublishing();
        }
      });
    },
    createRow: function($list, $row, index) {
      $row.addClass('working');

      var $form = $list.closest('section').find('.new_list_item');
      var createURL = $form.attr('action');

      $.ajax(createURL, {
        type: 'POST',
        data: JSON.stringify({
          list_item: {
            index: index,
            title: $row.data('title'),
            base_path: $row.data('base-path')
          }
        }),
        contentType: 'application/json',
        dataType: 'json',
        headers: { 'X-CSRF-Token': csrfToken },
        success: function(data) {
          $row.removeClass('working');
          $row.data({ 'update-url': data['updateURL'] });
          GOVUK.publishing.unlockPublishing();
        }
      });
    },
    deleteRow: function($row) {
      $row.addClass('working');

      var deleteURL = $row.data('update-url');

      if (!deleteURL) {
        return;
      }

      $.ajax(deleteURL, {
        type: 'DELETE',
        contentType: 'application/json',
        dataType: 'json',
        headers: { 'X-CSRF-Token': csrfToken },
        success: function() {
          $row.removeClass('working');
          $row.remove();
          GOVUK.curatedLists.redrawUncategorizedList();
          GOVUK.publishing.unlockPublishing();
        }
      });
    },
    activateRemoveButtons: function () {
      $('.curated-list').on('click', '.remove-button', function (e) {
        e.preventDefault();
        var $row = $(e.currentTarget).parent().parent().parent('tr');
        GOVUK.curatedLists.deleteRow($row);
        GOVUK.curatedLists.showEmptyLabels();
        return false;
      })
    },
    showEmptyLabels: function () {
      $('.curated-list').each(function(_, list) {
        if ($(list).children().not('.empty-list').length <= 0) {
          $(list).children('.empty-list').show();
        } else {
          $(list).children('.empty-list').hide();
        }
      });
    },
    redrawUncategorizedList: function () {
      $('.is-curated').removeClass('is-curated');
      $(".drag-and-droppable tr").each(function() {
        var path = $(this).data('base-path')
        $("[data-base-path='" + path + "']").addClass('is-curated');
      })
    }
  };
}());
