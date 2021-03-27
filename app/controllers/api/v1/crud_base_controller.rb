class Api::V1::CrudBaseController < Api::V1::ApplicationController
  def index
    render json: all_resources, status: :ok
  end

  def show
    return render json: { error: "#{model_name_as_title} not found" }, status: :not_found if resource.blank?

    render json: resource, status: :ok
  end

  def create
    # result = model.create resource_params
    result = all_resources.new resource_params

    unless result.valid?
      return render json: { errors: result.errors.messages },
                    status: :unprocessable_entity
    end

    # The response should be rendered in the post_process_create method, if unsuccessful
    return unless post_process_create(result, resource_params)

    if !result.save || result.errors.present?
      return render json: { errors: result.errors.messages },
                    status: :unprocessable_entity
    end

    render json: { data: ActiveModelSerializers::SerializableResource.new(result), message: "#{model_name_as_title} Created" }, status: :ok
  end

  def update
    return render json: { error: "#{model_name_as_title} not found" }, status: :not_found if resource.blank?

    resource.assign_attributes resource_params

    unless resource.valid?
      return render json: { errors: resource.errors.messages },
                    status: :unprocessable_entity
    end

    # The response should be rendered in the post_process_update method, if unsuccessful
    return unless post_process_update(resource, resource_params)

    if !resource.save || resource.errors.present?
      return render json: { errors: resource.errors.messages },
                    status: :unprocessable_entity
    end

    render json: { data: ActiveModelSerializers::SerializableResource.new(resource), message: "#{model_name_as_title} Updated OK" }, status: :ok
  end

  def destroy
    return render json: { error: "#{model_name_as_title} not found" }, status: :not_found if resource.blank?

    # The response should be rendered in the post_process_destroy method, if unsuccessful
    return unless post_process_destroy(resource)

    unless resource.destroy
      return render json: { errors: "#{model_name_as_title} was not able to be deleted" },
                    status: :unprocessable_entity
    end

    render json: { message: "#{model_name_as_title} deleted OK" }, status: :ok
  end

  protected

  # This is a hook to allow post-processing like API
  # Return result unless rendering an error
  def post_process_create(result, _resource_params)
    result
  end

  # This is a hook to allow post-processing like API
  # Return result unless rendering an error
  def post_process_update(result, _resource_params)
    result
  end

  # This is a hook to allow post-processing like API
  # Return result unless rendering an error
  def post_process_destroy(result)
    result
  end

  # This should be overridden in subclasses, if needed
  def model_name
    self.class.name.split('::').last.split('Controller').first.singularize
  end

  def model_name_as_sym
    model_name.underscore.to_sym
  end

  def model_name_as_title
    model_name.titleize
  end

  def model
    @model ||= model_name&.constantize
  end

  # This should be overridden in subclasses, if needed
  def resource
    @resource ||= all_resources.find_by(id: resource_id)
  end

  def all_resources
    @all_resources ||= model.all
  end

  def resource_id
    params.permit(:id)[:id].to_s
  end

  # This should be overridden in subclasses, if needed
  def resource_params
    @resource_params ||= params.require(model_name_as_sym).permit(
      %i[id]
    )
  end
end