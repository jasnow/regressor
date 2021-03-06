class RegressionModel

  attr_accessor :model

  def initialize(model)
    @model = model
  end

  def belong_to_relations
    @model.constantize.reflect_on_all_associations(:belongs_to).map(&:name).map do |relation|
      "it { is_expected.to belong_to :#{relation}}"
    end.join("\n\t") rescue nil
  end

  def has_one_relations
    @model.constantize.reflect_on_all_associations(:has_one).map(&:name).map do |relation|
      "it { is_expected.to have_one :#{relation}}"
    end.join("\n\t") rescue nil
  end

  def has_many_relations
    @model.constantize.reflect_on_all_associations(:has_many).map(&:name).map do |relation|
      "it { is_expected.to have_many :#{relation}}"
    end.join("\n\t") rescue nil
  end

  def validators
    validator_specs = []
    @model.constantize.validators.each do |validator|
      if validator.class.to_s == ActiveRecord::Validations::PresenceValidator.to_s
        validator.attributes.each do |attribute|
          validator_specs << "it { is_expected.to validate_presence_of :#{attribute} }"
        end
      end
      if validator.class.to_s == ActiveModel::Validations::LengthValidator.to_s
        validator.attributes.each do |attribute|
          minimum = validator.options[:minimum]
          maximum = validator.options[:maximum]
          validator_specs << "it { is_expected.to allow_value(Faker::Lorem.characters(#{minimum})).for :#{attribute} }" if minimum
          validator_specs << "it { is_expected.not_to allow_value(Faker::Lorem.characters(#{minimum - 1})).for :#{attribute} }" if minimum
          validator_specs << "it { is_expected.to allow_value(Faker::Lorem.characters(#{maximum})).for :#{attribute} }" if maximum
          validator_specs << "it { is_expected.not_to allow_value(Faker::Lorem.characters(#{maximum + 1})).for :#{attribute} }" if maximum
        end
      end
    end rescue []
    validator_specs.compact.uniq.join("\n\t")
  end

  def nested_attributes
    if @model.constantize.nested_attributes_options.present?
      @model.constantize.nested_attributes_options.keys.map do |key|
        "it { is_expected.to accept_nested_attributes_for :#{key} }"
      end.join("\n\t") rescue nil
    end
  end

  def database_columns
    @model.constantize.columns.map(&:name).map do |column|
      "it { is_expected.to have_db_column :#{column} }"
    end.join("\n\t") rescue nil
  end

  def database_indexes
    ActiveRecord::Base.connection.indexes(@model.tableize.gsub("/", "_")).map do |indexes|
        "it { is_expected.to have_db_index #{indexes.columns}}"
    end.flatten.join("\n\t") rescue nil
  end

end