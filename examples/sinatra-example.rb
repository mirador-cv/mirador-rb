require 'sinatra'
require 'mirador'

mirador_client = Mirador::Client.new ENV['MIRADOR_API_KEY']

post '/proxy/mirador/url' do
  content_type :json

  mirador_client.classify_url(request['url']).to_json
end

post '/proxy/mirador/datauri' do
  content_type :json

  mirador_client.classify_data_uri(request['id'] => request['data']).to_json
end

get '/' do

  <<-eot
<!doctype html>
<style> #display.safe { border: 5px solid #0e0; } #display.unsafe { border: 5px solid #e00; }</style>
<script src="//code.jquery.com/jquery-1.11.0.min.js"></script>

<input type='url' id='url'/>
<input type='file' id='file'/>
<img src='' width=400 id='display'/>
<span id='res-safe'></span>

<script>
var $doc = $(document),
    $display = $('#display'),
    $safe = $('#res-safe');

function onresult(res) {
  var safetxt = res.safe ? 'safe' : 'unsafe';
  $safe.text(safetxt + ': ' + res.value.toString().substr(0, 4));
  $display.attr('class', safetxt);
}

$doc.on('change', '#url', function (e) {
  $.post('/proxy/mirador/url', { url: this.value }).done(onresult);
  $display.attr('src', this.value);
});

$doc.on('change', '#file', function (e) {
  var file = this.files[0];
  if (!file) return;

  var reader = new FileReader();
  reader.onload = function (e) {
    $display.attr('src', e.target.result);

    $.post(
      '/proxy/mirador/datauri',
      { id: file.name, data: e.target.result }
    ).done(onresult);

  };


  reader.readAsDataURL(file);
});
</script>
eot

end
