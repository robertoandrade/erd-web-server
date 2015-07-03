$(function() {
  var $erdText = $("#erdText");
  var erdText = $erdText[0];
  var $status = $('#status');

  var editor = CodeMirror.fromTextArea(erdText, {
    lineNumbers: true
  });

  var generateDiagram = function() {
    var erCode = editor.getValue();

    $status.html('Generating...');

    console.log('Generating diagram for:', erCode);

    promise.post('/generate', erCode)
      .then(function(error, text, xhr) {
         if (error) {
             console.error('Error', xhr.status);
             return;
         }

         try {
          if (text) {
            text = text.replace(/\n/g, '\\n');
          }
          var data = JSON.parse(text);

          console.log('Response:', data);
         } catch (e) {
           console.error('Error', e, '\nJSON:', text);

           var data = { error: e };
         }

         if (data && data.image) {
            $('#generatedImage')
              .attr('src', data.image)
              .on('load', function() {
                $status.html('Success!');
              });
         } else {
            $status.html('<pre>Error: ' + data.error + '</pre>');
         }
      });
  };

  var loadSample = function() {
    var sampleURL = new URL(this.href || document.location).hash.substring(1);

    $status.html('Loading...');
    console.log("Loading sample:", sampleURL);

    $erdText.load(sampleURL, function() {
      editor.setValue($erdText.text());

      generateDiagram();
    });
  };

  //Generate diagram for any ER text POSTed to the page (via erdText parameter or body of POST)
  if ($erdText.text()) {
    generateDiagram();
  }

  //Load any ER text from external URL passed as a #hash component of the URL
  if (document.location.hash) {
    loadSample();
  }

  $("#generateLink").on('click', generateDiagram);
  $('.formatSample').on('click', loadSample);

  $('#parseERDLink').on('click', function(event) {
    $('.parseERDNotice').load(new URL(this.href).hash.substring(1) + '?' + Math.random());
    event.preventDefault();
  });
});