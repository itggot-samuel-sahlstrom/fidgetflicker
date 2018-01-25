class App < Sinatra::Base

	enable :sessions

	get '/' do
		slim :index
	end

	get '/register' do
		slim :register
	end

	get '/login' do
		slim :login
	end

	post '/register_user' do
		db = SQLite3::Database.new("database.db")

		username = params[:username]
		password = params[:password]

		password_digest = BCrypt::Password.create(password)


		# 'State' = 0; Offline. 'State' = 1; Online. 'State' = 2; Away.

		db.execute("INSERT INTO Users(username,password,state) VALUES(?,?,0)", [username,password_digest])
		redirect('/')
	end

	post '/login_user' do

		db = SQLite3::Database.new("database.db")

		username = params[:username]
		password = params[:password]

		id, username_verify, password_verify, state, score, highscore = db.execute("SELECT * FROM Users WHERE username = '#{username}'")[0]

		if password_verify != nil
			password_verify = BCrypt::Password.new(password_verify)
		else
			password_verify = ""
		end

		if username == username_verify && password_verify == password
			# Login successful
			session[:id] = id
			redirect('/profile/' + session[:id].to_s)
		else
			redirect('/error')
		end

	end

	get '/profile/:id' do

		id = params[:id].to_i

		if id != session[:id]
			redirect('/error')
		end
		
		session[:id] = params[:id].to_i

		if(session[:id])
			db = SQLite3::Database.new('database.db')
			db.results_as_hash = true

			result = db.execute("SELECT * FROM Relations WHERE User_1 OR User_2 = ?", [session[:id]])

			slim(:menu, locals:{notes:result})
		else
			redirect('/')
		end

	end

	post '/friend_request' do

		db = SQLite3::Database.new("database.db")

		User_sender = session[:id].to_i
		User_reciever = params[:request_user].to_i

		# 0 = Pending, 1 = Accepted, 2 = Denied, 3 = Blocked

		if User_sender < User_reciever
			db.execute("INSERT INTO Relations(User_1,User_2,Relation_State,User_Action) VALUES(?,?,0,?)", [User_sender, User_reciever, User_sender])
		elsif User_reciever < User_sender
			db.execute("INSERT INTO Relations(User_1,User_2,Relation_State,User_Action) VALUES(?,?,0,?)", [User_reciever, User_sender, User_sender])
		else
			redirect('/error')
		end

		redirect('/profile/' + session[:id].to_s)

	end



end           
