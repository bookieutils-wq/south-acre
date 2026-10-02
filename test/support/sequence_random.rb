class SequenceRandom
  def initialize(floats: [], ints: [])
    @floats = floats.dup
    @ints = ints.dup
  end

  def rand(limit = nil)
    if limit.nil?
      raise "unexpected float roll" if @floats.empty?

      @floats.shift
    else
      raise "unexpected integer roll" if @ints.empty?

      @ints.shift
    end
  end
end
