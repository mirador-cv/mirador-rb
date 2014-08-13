module Mirador

  #TODO: add more specific errors/subclasses

  class ApiError < StandardError
  end

  class RequestArgumentError < ApiError
  end

  class AuthenticationError < ApiError
  end

end
