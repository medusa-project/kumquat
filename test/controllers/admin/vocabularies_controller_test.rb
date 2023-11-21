require 'test_helper'

module Admin

  class VocabulariesControllerTest < ActionDispatch::IntegrationTest

    setup do
      @vocabulary = vocabularies(:lcsh)
    end

    # create()

    test "create() redirects to sign-in page for signed-out users" do
      post admin_vocabularies_path
      assert_redirected_to signin_path
    end

    test "create() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_vocabularies_path,
           xhr: true,
           params: {
             vocabulary: {
               key:  "new",
               name: "Name"
             }
           }
      assert_response :forbidden
    end

    test "create() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      post admin_vocabularies_path,
           xhr: true,
           params: {
             vocabulary: {
               key:  "new",
               name: "Name"
             }
           }
      assert_response :ok
    end

    # delete_vocabulary_terms()

    test "delete_vocabulary_terms() redirects to sign-in page for signed-out users" do
      post admin_vocabulary_delete_vocabulary_terms_path(@vocabulary)
      assert_redirected_to signin_path
    end

    test "delete_vocabulary_terms() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_vocabulary_delete_vocabulary_terms_path(@vocabulary)
      assert_response :forbidden
    end

    test "delete_vocabulary_terms() redirects upon success" do
      sign_in_as(users(:medusa_admin))
      post admin_vocabulary_delete_vocabulary_terms_path(@vocabulary),
           params: {
             vocabulary_terms: @vocabulary.vocabulary_terms.map(&:id)
           }
      assert_redirected_to admin_vocabulary_path(@vocabulary)
    end

    test "delete_vocabulary_terms() deletes the instance's terms" do
      sign_in_as(users(:medusa_admin))
      @vocabulary.vocabulary_terms.build(string: "cats").save!
      post admin_vocabulary_delete_vocabulary_terms_path(@vocabulary),
           params: {
             vocabulary_terms: @vocabulary.vocabulary_terms.map(&:id)
           }

      @vocabulary.reload
      assert_empty @vocabulary.vocabulary_terms
    end

    # destroy()

    test "destroy() redirects to sign-in page for signed-out users" do
      delete admin_vocabulary_path(@vocabulary)
      assert_redirected_to signin_path
    end

    test "destroy() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      delete admin_vocabulary_path(@vocabulary)
      assert_response :forbidden
    end

    test "destroy() redirects upon success" do
      sign_in_as(users(:medusa_admin))
      delete admin_vocabulary_path(@vocabulary)
      assert_redirected_to admin_vocabularies_path
    end

    test "destroy() destroys the instance" do
      sign_in_as(users(:medusa_admin))
      delete admin_vocabulary_path(@vocabulary)
      assert_raises ActiveRecord::RecordNotFound do
        @vocabulary.reload
      end
    end

    # import()

    test "import() redirects to sign-in page for signed-out users" do
      post admin_vocabulary_import_path(@vocabulary)
      assert_redirected_to signin_path
    end

    test "import() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      post admin_vocabulary_import_path(@vocabulary)
      assert_response :forbidden
    end

    test "import() redirects upon success" do
      sign_in_as(users(:medusa_admin))
      post admin_vocabulary_import_path(@vocabulary)
      assert_redirected_to admin_vocabularies_path
    end

    # index()

    test "index() redirects to sign-in page for signed-out users" do
      get admin_vocabularies_path
      assert_redirected_to signin_path
    end

    test "index() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_vocabularies_path
      assert_response :forbidden
    end

    test "index() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      get admin_vocabularies_path
      assert_response :ok
    end

    # show()

    test "show() redirects to sign-in page for signed-out users" do
      get admin_vocabulary_path(@vocabulary)
      assert_redirected_to signin_path
    end

    test "show() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      get admin_vocabulary_path(@vocabulary)
      assert_response :forbidden
    end

    test "show() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      get admin_vocabulary_path(@vocabulary)
      assert_response :ok
    end

    test "show() returns JSON" do
      sign_in_as(users(:medusa_admin))
      get admin_vocabulary_path(@vocabulary, format: :json)
      assert response.content_type.start_with?("application/json")
    end

    # update()

    test "update() redirects to sign-in page for signed-out users" do
      patch admin_vocabulary_path(@vocabulary)
      assert_redirected_to signin_path
    end

    test "update() returns HTTP 403 for unauthorized users" do
      sign_in_as(users(:normal))
      patch admin_vocabulary_path(@vocabulary),
            xhr: true,
            params: {
              vocabulary: {
                key:  "new",
                name: "New"
              }
            }
      assert_response :forbidden
    end

    test "update() returns HTTP 200" do
      sign_in_as(users(:medusa_admin))
      patch admin_vocabulary_path(@vocabulary),
            xhr: true,
            params: {
              vocabulary: {
                key:  "new",
                name: "New"
              }
            }
      assert_response :ok
    end

  end

end
