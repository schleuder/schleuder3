class StandardError
  def to_s
    super + "\n#{self.backtrace.join("\n")}\n"
  end
end