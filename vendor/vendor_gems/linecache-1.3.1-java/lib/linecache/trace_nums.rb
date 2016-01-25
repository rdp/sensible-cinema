# Provides stub alternative to lnums_for_str C implementation.

module TraceLineNumbers

  # Trivial implementation allowing to stop on every line.
  def lnums_for_str(code)
    (1..code.lines.count).to_a
  end
  module_function :lnums_for_str

end
