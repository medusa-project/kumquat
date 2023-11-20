require 'test_helper'

class VocabularyTermsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @term       = vocabulary_terms(:augmented)
    @vocabulary = @term.vocabulary
  end

  # create()

  test "create() redirects to sign-in page for signed-out users" do
    post admin_vocabulary_vocabulary_terms_path(@vocabulary)
    assert_redirected_to signin_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    post admin_vocabulary_vocabulary_terms_path(@vocabulary),
         xhr: true,
         params: {
           vocabulary_term: {
             string:        "new",
             vocabulary_id: @vocabulary.id
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    post admin_vocabulary_vocabulary_terms_path(@vocabulary),
         xhr: true,
         params: {
           vocabulary_term: {
             string:        "new",
             vocabulary_id: @vocabulary.id
           }
         }
    assert_response :ok
  end

  # destroy()

  test "destroy() redirects to sign-in page for signed-out users" do
    delete admin_vocabulary_vocabulary_term_path(@vocabulary, @term)
    assert_redirected_to signin_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    delete admin_vocabulary_vocabulary_term_path(@vocabulary, @term)
    assert_response :forbidden
  end

  test "destroy() redirects upon success" do
    sign_in_as(users(:medusa_admin))
    delete admin_vocabulary_vocabulary_term_path(@vocabulary, @term)
    assert_redirected_to admin_vocabulary_vocabulary_terms_path(@vocabulary)
  end

  test "destroy() destroys the instance" do
    sign_in_as(users(:medusa_admin))
    delete admin_vocabulary_vocabulary_term_path(@vocabulary, @term)
    assert_raises ActiveRecord::RecordNotFound do
      @term.reload
    end
  end

  # edit()

  test "edit() redirects to sign-in page for signed-out users" do
    get edit_admin_vocabulary_vocabulary_term_path(@vocabulary, @term)
    assert_redirected_to signin_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get edit_admin_vocabulary_vocabulary_term_path(@vocabulary, @term)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    get edit_admin_vocabulary_vocabulary_term_path(@vocabulary, @term)
    assert_response :ok
  end

  # index()

  test "index() redirects to sign-in page for signed-out users" do
    get admin_vocabulary_vocabulary_terms_path(@vocabulary)
    assert_redirected_to signin_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    get admin_vocabulary_vocabulary_terms_path(@vocabulary)
    assert_response :forbidden
  end

  test "index() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    get admin_vocabulary_vocabulary_terms_path(@vocabulary, format: :json)
    assert_response :ok
  end

  # update()

  test "update() redirects to sign-in page for signed-out users" do
    patch admin_vocabulary_vocabulary_term_path(@vocabulary, @term)
    assert_redirected_to signin_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    sign_in_as(users(:normal))
    patch admin_vocabulary_vocabulary_term_path(@vocabulary, @term),
          xhr: true,
          params: {
            vocabulary_term: {
              string: "New String"
            }
          }
    assert_response :forbidden
  end

  test "update() returns HTTP 200" do
    sign_in_as(users(:medusa_admin))
    patch admin_vocabulary_vocabulary_term_path(@vocabulary, @term),
          xhr: true,
          params: {
            vocabulary_term: {
              string: "New String"
            }
          }
    assert_response :ok
  end

end
