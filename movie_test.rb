class MovieTest
	
	attr_accessor :list_of_results

	# A tuple structure that stores user, movie, rating, and prediction information.
	Test = Struct.new(:user, :movie, :rating, :prediction)

	def initialize
		@list_of_results = Array.new
		@mean_error = -1
	end

	##
	# Insert a tuple into MovieTest with user, movie, rating, and prediction info.
	def add params
		user 			= params[:user]
		movie 			= params[:movie]
		rating 			= params[:rating]
		prediction 		= params[:prediction]
		list_of_results.push(Test.new(user, movie, rating, prediction))
	end

	##
	# Returns the average predication error (which should be close to zero)
	def mean
		sum_error = 0
		@list_of_results.each { |tuple| sum_error += err(tuple) }

		@mean_error = sum_error / @list_of_results.size
	end

	##
	# Returns the standard deviation of the error.
	def stddev
		sq_diff_sum = 0
		@list_of_results.each { |tuple| sq_diff_sum += squared_differences(err(tuple)) }

		std_dev = Math.sqrt(sq_diff_sum / @list_of_results.size)
	end

	##
	# Returns the squared difference of the overall mean and the error.
	def squared_differences error
		error = error - @mean_error
		sq_diff = error ** 2
	end

	##
	# Returns the root mean square error of the prediction, our primary error measure. 
	# RMSE <- sqrt(mean((y-y_pred)^2))
	def rms
		rms_sum = 0
		@list_of_results.each { |tuple| rms_sum += err(tuple) ** 2 }

		Math.sqrt(rms_sum / @list_of_results.size)
	end

	##
	# Get the error of a tuple.
	def err tuple
		if tuple.rating != -1 then (tuple.rating - tuple.prediction).abs else 0 end
	end

	##
	# Returns an array of the predictions in the form [u,m,r,p].
	def to_a
		return list_of_results
	end


end