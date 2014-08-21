require 'rubygems'
require 'sinatra'

# @todo Restructure
require '/usr/lib64/ruby/vendor_ruby/zorba_api'

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Public User'
  end
end

before '/secure/*' do
  if !session[:identity] then
    session[:previous_url] = request.path
    @error = 'Please authenticate to visit ' + request.path
    halt erb(:login_form)
  end
end

# Index
get '/' do

  erb 'A TEI XQuery API using Zorba'
end

# Documentation
get '/doc' do

  erb 'Transmit GET requests with the encoded XQuery within the "q" parameter <a href="/xquery">to /xquery</a>.  This documentation is to be further drafted and extended.'
end

# XQuery interface
get '/xquery' do

  @store = Zorba_api::InMemoryStore.getInstance()
  @zorba = Zorba_api::Zorba.getInstance(@store)
  dataManager = @zorba.getXmlDataManager()
  docMgr = dataManager.getDocumentManager()

  # @todo Structure to parse the Document store directory
  docIter = dataManager.parseXML("<books><book>Book 1</book><book>Book 2</book></books>")
  docIter.open()

  # Iterate over each item
  doc = Zorba_api::Item::createEmptyItem()
  docIter.next(doc)
  docIter.destroy()

  # Place the document into a given collection
  docMgr.put("books.xml", doc);

  # @todo Provide a demonstration XQuery
  query = params[:q] || "doc('books.xml')//book"

  # @todo Handle exceptions
  xquery = @zorba.compileQuery(query)
  response = xquery.execute()
  xquery.destroy()

  # Remove the documents
  docMgr.remove("books.xml")

  # Set the MIME type and transmit the response
  content_type 'application/xml'
  response
end

# Authentication

get '/login/form' do 
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from 
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end


get '/secure/place' do
  erb "This is a secret place that only <%=session[:identity]%> has access to!"
end
