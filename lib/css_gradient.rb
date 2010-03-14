class GradientToken < Struct.new(:rgb_def, :ratio)

  def rgb_str
    "rgb(#{rgb_def.join(',')})"
  end

  def to_webkit
    "color-stop(#{ratio / 100.0}, #{rgb_str})"
  end

  def to_moz
    "#{rgb_str} #{ratio}%"
  end

end

class CssGradient

  attr_reader :property

  def initialize(property, *components)
    @property = property
    @components = components.map { |c| GradientToken.new(*c)}
  end

  def to_webkit
    content = <<-eoq
      #{property}: -webkit-gradient(
        linear,
        left bottom,
        left top,
        #{@components.map { |c| c.to_webkit }.join(",\n")}
      );
    eoq
  end

  def to_moz
    content = <<-eoq
      #{property}: -moz-linear-gradient(
        center bottom,
        #{@components.map { |c| c.to_moz }.join(",\n")}
      );
    eoq
  end

  def to_s
    [to_webkit, to_moz].join("\n")
  end

end
