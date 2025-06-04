# frozen_string_literal: true

class ApplicationService
  extend Dry::Initializer

  Types = Dry::Types()

  class Error < StandardError; end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  def errors
    @errors ||= []
  end

  def call
    process
    self
  rescue Error
    self
  end

  def halt(*messages)
    errors.concat(messages)
    raise Error
  end

  def success?
    errors.empty?
  end

  def failure?
    !success?
  end

  # Абстрактный метод, должен быть реализован в наследнике
  def process
    raise NotImplementedError, 'You must implement #process in your service'
  end
end
