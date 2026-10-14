# frozen_string_literal: true

require "test_helper"
require "yaml"

# Ensures production call sites for gem keys do not hand-copy English from
# en.yml (or constants equal to those strings) as `default:`. English fallback
# comes from RecordingStudio.t / loaded :en / register_shipped_english instead.
#
# Admin DSL (`lib/recording_studio_pages/admin.rb`) stays literal/`default:` as
# on main and is skipped. Scanner covers single-quoted, double-quoted,
# multi-line, paren-less, I18n.translate, constant, and Array defaults.
class EnglishDefaultDriftGuardTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SCAN_GLOBS = %w[
    app/**/*.{rb,erb}
    lib/**/*.rb
  ].freeze
  SKIP_PATH_FRAGMENTS = %w[
    /generators/
    /admin.rb
  ].freeze

  TRANSLATION_CALL = /
    (?:
      RecordingStudioPages::Copy\.t |
      RecordingStudio\.t |
      Copy\.t |
      I18n\.(?:t|translate)
    )
  /x

  def test_production_translation_calls_do_not_hand_copy_en_yml_english_defaults
    en_values = en_yml_leaf_values
    constant_values = known_message_constants

    offenders = []
    scan_files.each do |path|
      source = File.read(path)
      source = strip_ruby_comments(source) if path.end_with?(".rb")

      each_translation_call(source) do |call_source|
        each_default_argument(call_source) do |default_src|
          next if allowed_dynamic_default?(default_src)

          values = default_values(default_src, constant_values)
          values.each do |value|
            next unless en_values.include?(value)

            offenders << "#{relative(path)}: default: #{default_src} => #{value.inspect}"
          end
        end
      end
    end

    assert_empty offenders, <<~MSG
      Hand-copied English default:s drift from en.yml. Remove them and rely on
      RecordingStudio.t / Copy.t fallback instead.
      #{offenders.join("\n")}
    MSG
  end

  def test_scanner_catches_single_quoted_multiline_paren_less_translate_constant_and_array_defaults
    sample = <<~RUBY
      Copy.t("index.title", default: 'Pages')
      Copy.t(
        "flashes.updated",
        default: "Updated."
      )
      RecordingStudio.t "recording_studio.pages.layout.page", default: "Page"
      I18n.translate("recording_studio.pages.settings.trash", default: "Trash")
      Copy.t("errors.choose_workspace", default: CHOOSE_WORKSPACE)
      Copy.t("index.title", default: ["Pages", "Other"])
    RUBY

    en_values = en_yml_leaf_values
    constant_values = { "CHOOSE_WORKSPACE" => "Choose a workspace for this page." }
    hits = []

    each_translation_call(sample) do |call_source|
      each_default_argument(call_source) do |default_src|
        hits.concat(default_values(default_src, constant_values).select { |value| en_values.include?(value) })
      end
    end

    assert_includes hits, "Pages"
    assert_includes hits, "Updated."
    assert_includes hits, "Page"
    assert_includes hits, "Trash"
    assert_includes hits, "Choose a workspace for this page."
    assert_equal 2, hits.count("Pages"), "array + single-quoted Pages"
  end

  private

  def scan_files
    SCAN_GLOBS.flat_map { |glob| Dir[File.join(ROOT, glob)] }
              .uniq
              .reject { |path| SKIP_PATH_FRAGMENTS.any? { |frag| path.include?(frag) } }
  end

  def relative(path)
    path.delete_prefix("#{ROOT}/")
  end

  def en_yml_leaf_values
    tree = YAML.safe_load_file(File.join(ROOT, "config/locales/en.yml"), aliases: true)
               .fetch("en").fetch("recording_studio").fetch("pages")
    flatten_values(tree).to_set
  end

  def flatten_values(node)
    case node
    when Hash then node.values.flat_map { |value| flatten_values(value) }
    when Array then node.flat_map { |value| flatten_values(value) }
    else [node]
    end
  end

  def known_message_constants
    {}
  end

  def strip_ruby_comments(source)
    source.gsub(/^\s*#.*$/, "")
  end

  def each_translation_call(source)
    index = 0
    while (match = source.match(TRANSLATION_CALL, index))
      start = match.end(0)
      call_body = extract_call_body(source, start, match[0])
      yield "#{match[0]}#{call_body}"
      index = start + 1
    end
  end

  def extract_call_body(source, start, method_name)
    return paren_body(source, start) if source[start] == "("
    if method_name.strip.match?(/\A(?:RecordingStudio\.t|I18n\.(?:t|translate))\z/)
      return " #{slice_until_newline(source, start)}"
    end

    ""
  end

  def paren_body(source, open_index)
    depth = 0
    i = open_index
    while i < source.length
      case source[i]
      when "(" then depth += 1
      when ")"
        depth -= 1
        return source[open_index..i] if depth.zero?
      when "'", '"'
        i = skip_string(source, i)
        next
      end
      i += 1
    end
    source[open_index..]
  end

  def skip_string(source, index)
    quote = source[index]
    index += 1
    while index < source.length
      return index + 1 if source[index] == quote && source[index - 1] != "\\"

      index += 1
    end
    index
  end

  def slice_until_newline(source, start)
    line_end = source.index(/\n/, start) || source.length
    source[start...line_end]
  end

  def each_default_argument(call_source)
    offset = 0
    while (match = call_source.match(/default:\s*/, offset))
      value = read_ruby_expression(call_source, match.end(0))
      yield value.strip
      offset = match.end(0) + value.length
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def read_ruby_expression(source, start)
    i = start
    i += 1 while i < source.length && source[i].match?(/\s/)
    return "" if i >= source.length

    case source[i]
    when "'", '"'
      finish = skip_string(source, i)
      source[i...finish]
    when "["
      depth = 0
      j = i
      while j < source.length
        case source[j]
        when "[" then depth += 1
        when "]"
          depth -= 1
          return source[i..j] if depth.zero?
        when "'", '"'
          j = skip_string(source, j)
          next
        end
        j += 1
      end
      source[i..]
    else
      j = i
      j += 1 while j < source.length && source[j].match?(/[A-Za-z0-9_:]/)
      source[i...j]
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def allowed_dynamic_default?(default_src)
    normalized = default_src.gsub(/\s+/, "")
    %w[
      definition.name
      english
      default
      name
      label.to_s
    ].include?(normalized)
  end

  def default_values(default_src, constant_values)
    if string_literal_default?(default_src)
      [eval_string_literal(default_src)]
    elsif array_literal_default?(default_src)
      extract_array_string_literals(default_src)
    elsif constant_default?(default_src)
      leaf = default_src.split("::").last
      Array(constant_values[default_src] || constant_values[leaf])
    else
      []
    end
  end

  def string_literal_default?(default_src)
    default_src.match?(/\A(['"]).*\1\z/m)
  end

  def array_literal_default?(default_src)
    default_src.start_with?("[")
  end

  def constant_default?(default_src)
    default_src.match?(/\A[A-Z][A-Za-z0-9_:]+\z/)
  end

  def eval_string_literal(literal)
    # rubocop:disable Security/Eval
    eval(literal)
    # rubocop:enable Security/Eval
  end

  def extract_array_string_literals(array_src)
    array_src.scan(/(['"])((?:\\.|(?!\1).)*)\1/).map do |quote, body|
      eval_string_literal("#{quote}#{body}#{quote}")
    end
  end
end
