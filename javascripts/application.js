
Event.addBehavior({

  'body': function() {
    var busy = $div({id:'busy'}, "Loading...");
    busy.hide();
    // NOTE You could also use 'this' here
    //      since it is the document.body.
    document.body.appendChild(busy);
    
    new Ajax.Request('/tracker');
  },
  
  // Article
  
  'a#spoiler:click': function() {
    new Ajax.Updater(this.parentNode, this.readAttribute('href'));
    return false;
  },
  
  'a#alt_spoiler:click': function() {
    new Ajax.Updater('the_rest_of_the_story', this.readAttribute('href'), {
      onComplete: function() {
        new Effect.Highlight('the_rest_of_the_story', { duration: 1.0 });
      }
    });
    return false;
  },
  
  'a#error:click': function() {
    new Ajax.Request(this.href, {
      onFailure: function(transport) {
        var response = transport.responseText || "Sorry, there was an error.";
        alert(response);
      }
    });
    return false;
  },
  
  // Edit
  
  'body#edit_page': function() {
    var preview_output = $div({id:'preview_output'});
    document.body.appendChild(preview_output);
  },
  
  'form#edit input[name=preview]:click': function() {
    this.form.request({
      onComplete: function() {
        new Effect.Highlight('preview_output');
      }
    });
    return false;
  },
  
  // Signup
  
  'form#signup': function() {
    var url_label = $label({'for':"url"}, 'Your hCard URL');
    var url_input = $input({type:'text', name:'url', id:'url'});
    // 'class' is a reserved word in Safari so we 
    // need to add it manually.
    url_input.addClassName('textfield');
    var url_button = $input({type:'button', name:'fetch', value:'Fetch Contact Info'});
    
    url_label.appendChild(url_input);
    url_label.appendChild(url_button);
    $$('form#signup div.form_element').first().addBefore(url_label);
        
    this.focusFirstElement();
  },

/*  
  // Example Only
  'form#signup label input#street-address': function() {
    new Form.Element.EventObserver(this, function(element, value) {
      // value is the value of the element
      alert(element + " is now " + this.form.serialize());
    }.bind(this));
  },

*/

  'form#signup label input#username:blur': function() {
    if ($F('username').blank()) {
      $('username_check').hide();
    } else {
      new Ajax.Request('/username_check', {
        parameters:this.form.serialize()
      });
    }
  },
  
  'form#signup label input#postal-code:blur': function() {
    new Ajax.Request('/postal_code_lookup', {
      parameters:this.form.serialize(),
      onSuccess: function(transport) {
        // NOTE Passing 'true' to evalJSON doesn't work with Rails.
        //      Not exactly sure why.
        var json = transport.responseText.evalJSON();
        $('locality').update(json['locality']);
        $('region').update(json['region']);
      }
    });
  },
  
  'form#signup input[name=fetch]:click': function() {
    if ($F('url').blank()) {
      // Do nothing
    } else {
      new Ajax.Request('/hcard_lookup', {
        parameters:this.form.serialize(),
        onSuccess: function(transport) {
          // NOTE Passing 'true' to evalJSON doesn't work with Rails.
          //      Not exactly sure why.
          var json = transport.responseText.evalJSON();
          $('locality').update(json['adr']['locality']);
          $('region').update(json['adr']['region']);
          $('postal-code').value = json['adr']['postal-code'];
          $('street-address').value = json['adr']['street-address'];
          HCard.data = json;
        },
        onFailure: function(transport) {
          var response = transport.responseText || "Sorry, there was an error.";
          alert(response);
        }
      });
    }
    
    return false;
  }
  
});

// This variable will be available to the entire application.
var HCard = {};

/* From http://mir.aculo.us/2005/11/14/ajax-activity-indicators-with-rails-0-14-3 */
Ajax.Responders.register({
  
  onCreate: function() {
    if($('busy') && Ajax.activeRequestCount > 0)
      Effect.Appear('busy',{duration:0.5,queue:'end'});
  },
  
  onComplete: function() {
    if($('busy') && Ajax.activeRequestCount == 0)
      Effect.Fade('busy',{duration:1.0,queue:'end'});
  }
    
});


/*
// Example Only
new PeriodicalExecuter(function() {
  new Ajax.Updater('timer', '/timer/show/1');
}, 120);

*/
