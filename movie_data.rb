# <b>Calvin Wang</b> <br>
# COSI 105B <br>
# Movies-2 <br>
# Things that would be nice to add: OptionsParser for debug and filename!
# Problems: MovieData, BinarySearchTree, and MovieTest are very coupled.

class MovieData

	require "./bst.rb"
	require "./movie_test.rb"

	attr_reader	:folder, :debug, :user_reviews, :m_stats, :movie_test, :num_predictions

	# Movie structure storing the count, sum, and average ratings,
	# as well as an array of users that watched this movie.
	Movie = Struct.new(:num_r, :total_r, :average_r, :viewers)

	# User structure, storing user id and a hash of movies watched
	User = Struct.new(:id, :movies)

	# UserMovie structure, storing the user id, the movie id, the rating and timestamp
	UserMovie = Struct.new(:u_id, :id, :rating, :timestamp)

	##
	# Initialize the MovieData object. Takes a path to the folder containing the movie data
	# (ml-100k for example) a second optional constructor can be used to specify that a 
	# particular base/training set pair should be read.
	def initialize f, test = nil
		@folder = f

		if test == nil
			@training_set_file = "u.data"
			@test_set_file = nil
		else
			@training_set_file = "#{test}.base"
			@test_set_file = "#{test}.test"
		end

		@num_predictions = 0
		@movie_test = MovieTest.new

		@user_reviews = Hash.new
		@test_set_user_reviews = Hash.new

		@m_stats = Hash.new
		@test_set_m_stats = Hash.new

		if ARGV[0] == "debug" then @debug = true else @debug = false end
	end

	##
	# Loads input file data into respective data structures.
	def load_data

		load_set("#{folder}/#{@training_set_file}", user_reviews, m_stats)
		load_set("#{folder}/#{@test_set_file}", @test_set_user_reviews, @test_set_m_stats)

		if debug
			puts "* * * training set size: #{user_reviews.size}"
			puts "* * * test set size: #{@test_set_user_reviews.size}"
		end
	end

	##
	# Reads file data and passes data into hashing methods.
	def load_set location, user_set, movie_set

		if !File.file?(location) then if debug then puts "#{location} does not exist!" end
		else
			if debug
				puts "* * * loaded #{location} * * *"
				count = 0
			end

			File.foreach("#{location}") do |line|
				line_array = line.split("\t")

				# the following methods will add info into each hashmap
				hash_reviews(user_set, line_array)
				hash_movies(movie_set, line_array[1].to_i, line_array[2].to_f, line_array[0].to_i)
				if debug then count = count + 1 end
			end
		end
		
		if debug then puts "* * * read #{count} lines" end

	end

	##
	# Creates a user_id => [movie id => [rating, timestamp]] k:v pair
	def hash_reviews user_set, line_array

		u_id = line_array[0].to_i				# user id
		m_id = line_array[1].to_i				# movie id
		um_rating = line_array[2].to_i	# rating
		um_time = line_array[3].to_i		# timestamp

		if user_set.has_key?(u_id)
			user_set[u_id].movies[m_id] = UserMovie.new(u_id, m_id, um_rating, um_time)
		else
			user_set[u_id] = User.new(u_id, Hash.new)
			user_set[u_id].movies[m_id] = UserMovie.new(u_id, m_id, um_rating, um_time)
		end
	end

	##
	# Creates a movie stats hashmap, movie_id => [item_count, item_total_r, item_average_r]
	def hash_movies movie_set, m_id, rating, u_id
		if movie_set.has_key?(m_id)
			movie_set[m_id].num_r += 1
			movie_set[m_id].total_r += rating
			movie_set[m_id].average_r = (movie_set[m_id].total_r + rating) / movie_set[m_id].num_r
			movie_set[m_id].viewers.push(u_id)
		else
			movie_set[m_id] = Movie.new(1, rating, rating)
			movie_set[m_id].viewers = []
			movie_set[m_id].viewers.push(u_id)
		end
	end

	##
	# Popularity is defined as (number of reviews + (average rating * number of reviews))
	# Rationale: a movie's overall rating is pretty important, as well as how many reviews
	# it has received.
	def popularity movie_id
		movie = m_stats[movie_id]
		return movie.num_r + (movie.average_r.round(2) * movie.num_r)
	end

	##
	# The popularity list is represented by a binary search tree. This allows fast gets,
	# as well as ordered display via in order traversal of the bst.
	def popularity_list frontBack
		pop_list_bst = BinarySearchTree.new(m_stats.keys.first, popularity(m_stats.keys.first))
		
		if debug then
			puts "\n* * * #{m_stats.length} movies * * * "
			puts "* * * made bst: root obj #{m_stats.keys.first}, val #{popularity(m_stats.keys.first).round(3)}."
		end

		m_stats.each_key { |id| pop_list_bst.insert(id, popularity(id)) }

		return traverse(pop_list_bst, frontBack)
	end

	##
	# Basic assumption: we're seeing how similar user2 is to user1. So we weigh user1's preferences
	# and ratios more than user2's, e.g. when we look at the movies-watched-in-common ratio.
	def similarity user1, user2
		common = find_common_movies(user1, user2)
		watched_sim = find_watched_similarity(common.length, user1, user2)
		r_diff = rating_difference(user1, user2, common)

		if debug then
			puts "* * *"
			puts "common: #{common.length} movies"
			puts "user 1: #{user_reviews[user1].movies.keys.length} movies"
			puts "user 2: #{user_reviews[user2].movies.keys.length} movies"
			print "common movies: "
			puts watched_sim.round(3)
			print "rating diff: "		
			puts r_diff
			puts "* * *"
		end

		return (watched_sim * (5 - r_diff))
	end

	##
	# Inserts a user's similarity value into the binary search tree if it is not 0.
	def most_similar u, frontBack
		sim_list_bst = BinarySearchTree.new(u, -1)
		user_reviews.each_key do |key| 
			similarity = similarity(u, key)
			if debug then puts "* * * similarity is 0, skipping bst insert for #{key}" end
			if similarity != 0.0 then sim_list_bst.insert(key, similarity) end
		end

		return traverse(sim_list_bst, frontBack)
	end

	##
	# Traverse the binary search tree, either in order or in reverse order.
	def traverse bst, frontBack
		if frontBack == "top"
			return bst.in_order_traversal
		elsif frontBack == "bottom"
			return bst.reverse_order_traversal
		else
			return nil
		end
	end

	##
	# Return the intersection of the movies reviewed by user1 and user2.
	def find_common_movies user1, user2
		return user_reviews[user1].movies.keys.to_a & user_reviews[user2].movies.keys.to_a
	end

	##
	# Returns a value (0 to 5.0) signifying the average rating difference between user1 and user2.
	def rating_difference user1, user2, common
		r_diff = 0
		if common.size == 0 then return 5.0 else
			common.each { |i|
				r_diff += (user_reviews[user1].movies[i].rating.to_f - 
					user_reviews[user2].movies[i].rating.to_f).abs }
			return r_diff / common.size
		end
	end

	##
	# Return the % of user1's movies that are in common with user2.
	# After all, we're seeing how similar user2 is to user1.
	def find_watched_similarity common_movies, user1, user2
		return (common_movies.to_f / user_reviews[user1].movies.keys.length.to_f)
	end

	##
	# Returns the rating that user u gave movie m in the training set, 
	# and 0 if user u did not rate movie m.
	def rating user_id, movie_id
		if user_reviews.has_key?(movie_id)
			puts user_reviews[user_id].movies[movie_id].rating
			return user_reviews[user_id].movies[movie_id].rating
		else return 0 end
	end

	##
	# Returns a floating point number between 1.0 and 5.0
	# as an estimate of what user u would rate movie m.
	# A better algorithm (for another time): look at most_similar users to user, get the movie ratings
	# of the most similar users, and use that average as the prediction. 
	def predict user_id, movie_id
		if m_stats[movie_id] != nil
			@num_predictions += 1
			return m_stats[movie_id].average_r
		else return 2.5 end
	end

	##
	# Returns the array of movies that user u has watched.
	def movies user_id
		return user_reviews[user_id].movies.keys.sort
	end

	##
	# Returns the array of users that have seen movie m.
	def viewers movie_id
		return m_stats[movie_id].viewers.sort
	end

	##
	# Runs the z.predict method on the first k ratings in the test set and returns a 
	# MovieTest object containing the results.
	# The parameter k is optional and if omitted, all of the tests will be run.
	def run_test num_users = 0
		if (num_users == 0 || num_users > @test_set_user_reviews.size)
			num_users = @test_set_user_reviews.size
		end

		time = Time.now

		reviews = @test_set_user_reviews.keys.to_a

		# the following is a nested loop... 
		(0...num_users).each do |k| 
			@test_set_m_stats.each_key do |m|
				if user_reviews[reviews[k]].movies[m] == nil
					rating = -1
				else rating = user_reviews[reviews[k]].movies[m].rating end
				
	 			@movie_test.add( {
	 				user: reviews[k], 
	 				movie: m, 
	 				rating: rating,
	 				prediction: predict(reviews[k], m)
	 			})
	 		end
	 	end

	 	#puts movie_test.list_of_results.size

	 	puts "Time spent running #{@num_predictions} predictions: #{(Time.now - time)} seconds.	"
	end

end