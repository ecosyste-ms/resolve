class Gem::Requirement
  OPS = { #:nodoc:
    "=" => lambda {|v, r| v == r },
    "!=" => lambda {|v, r| v != r },
    ">" => lambda {|v, r| v >  r },
    "<" => lambda {|v, r| v <  r },
    ">=" => lambda {|v, r| v >= r },
    "<=" => lambda {|v, r| v <= r },
    "~>" => lambda {|v, r| v >= r && v.release < r.bump },
    "~" => lambda {|v, r| v >= r && v.release < r.bump },
    "^" => lambda {|v, r| v >= r && v.release < r.bump },
  }.freeze

  quoted = OPS.keys.map {|k| Regexp.quote k }.join "|"
  PATTERN_RAW = "\\s*(#{quoted})?\\s*(#{Gem::Version::VERSION_PATTERN})\\s*".freeze # :nodoc:

  ##
  # A regular expression that matches a requirement

  PATTERN = /\A#{PATTERN_RAW}\z/.freeze
end

module VersionParser
  extend self

  def requirement_to_range(requirement)
    ranges = requirement.requirements.map do |(op, ver)|
      case op
      when "~>"
        name = "~> #{ver}"
        bump = ver.class.new(ver.bump.to_s + ".A")
        PubGrub::VersionRange.new(name: name, min: ver, max: bump, include_min: true)
      when "~"
        name = "~ #{ver}"
        bump = ver.class.new(ver.bump.to_s + ".A")
        PubGrub::VersionRange.new(name: name, min: ver, max: bump, include_min: false)
      when "^"
        name = "^ #{ver}"
        bump = ver.class.new(ver.bump.to_s + ".A")
        PubGrub::VersionRange.new(name: name, min: ver, max: bump, include_min: false)
      when ">"
        PubGrub::VersionRange.new(min: ver)
      when ">="
        PubGrub::VersionRange.new(min: ver, include_min: true)
      when "<"
        PubGrub::VersionRange.new(max: ver)
      when "<="
        PubGrub::VersionRange.new(max: ver, include_max: true)
      when "="
        PubGrub::VersionRange.new(min: ver, max: ver, include_min: true, include_max: true)
      when "!="
        PubGrub::VersionRange.new(min: ver, max: ver, include_min: true, include_max: true).invert
      else
        raise "bad version specifier: #{op}"
      end
    end

    ranges.inject(&:intersect)
  end

  def requirement_to_constraint(package, requirement)
    PubGrub::VersionConstraint.new(package, range: requirement_to_range(requirement))
  end

  def parse_range(dep)
    dep = Array(dep).join(' ')
    dep = SemanticRange::Range.new(dep).format.split(' ')
    requirement_to_range(Gem::Requirement.new(dep))
  end

  def parse_constraint(package, dep)
    range = parse_range(dep)
    PubGrub::VersionConstraint.new(package, range: range)
  end
end

