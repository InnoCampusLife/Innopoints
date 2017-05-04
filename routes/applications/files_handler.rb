require 'sinatra'

module Applications
  module FilesHandler
    def self.registered(app)
# UploadFile
      app.post URL + '/accounts/:token/files' do
      # app.post URL + '/files' do
        token = params[:token]
        return generate_response('fail', nil, 'ERROR IN PARAMS', CLIENT_ERROR_CODE) if params.nil? || !params.is_a?(Hash)
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          account = Account.get_by_owner(resp[:result][:id])
          if account.nil?
            return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            files = Hash.new
            params.each do |key, file_data|
              if file_data.is_a?(Hash)
                if file_data[:filename].nil? || file_data[:type].nil? || file_data[:name].nil? || file_data[:tempfile].nil? || file_data[:head].nil?
                  next
                  # return generate_response('fail', nil, 'ERROR IN FILE PARAMETERS', CLIENT_ERROR_CODE)
                end
                if File.size(file_data[:tempfile]) > MAX_FILE_SIZE
                  return generate_response('fail', nil, 'MAX FILE SIZE IS 10 MB', CLIENT_ERROR_CODE)
                end
                files[key] = file_data
              end
            end
            return generate_response('fail', nil, 'THERE ARE NO FILES', CLIENT_ERROR_CODE) if files.length == 0
            result = []
            files.each do |key, file_data|
              file_name = file_data[:filename]
              name_parts = file_name.split('.')
              extension = ''
              if name_parts.length > 1
                (1..(name_parts.length - 1)).each { |i|
                  extension += ('.' + name_parts[i])
                }
              end
              puts 'BEFORE FILE CREATION'
              created_file = StoredFile.create(file_name, extension)
              puts 'AFTER FILE CREATION'
              folder = Dir.pwd + FILES_FOLDER
              unless File.directory?(folder)
                FileUtils::mkdir_p(folder)
              end
              File.open(folder + '/' + created_file[:id].to_s + extension, 'w') do |f|
                f.write(file_data[:tempfile].read)
              end
              result.push({
                              id: created_file[:id],
                              filename: key
                          })
            end
            return generate_response('ok', result, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# DownloadFile
      app.get URL + '/accounts/:token/files/:file_id' do
        content_type :json
        token = params[:token]
        file_id = validate_integer(params[:file_id])
        if file_id.nil?
          return generate_response('fail', nil, 'WRONG FILE ID', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          account = Account.get_by_owner(resp[:result][:id])
          if account.nil?
            return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            file = StoredFile.get_with_author_by_id(file_id)
            if file.nil?
              return generate_response('fail', nil, 'FILE DOES NOT EXIST', CLIENT_ERROR_CODE)
            end
            if account[:type] == 'admin'
              file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + file_id.to_s + file[:extension]
              if File.exists?(file_url)
                send_file file_url, :filename => file[:filename], :type => 'Application/octet-stream'
              else
                generate_response('fail', nil, 'FILE DOES NOT EXIST ON SERVER', SERVER_ERROR_CODE)
              end
            else
              unless account[:id] == file[:account_id]
                return generate_response('fail', nil, 'USER DOES NOT HAVE ACCESS TO THE FILE', SERVER_ERROR_CODE)
              end
              file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + file_id.to_s + file[:extension]
              if File.exists?(file_url)
                send_file file_url, :filename => file[:filename], :type => 'Application/octet-stream'
                generate_response('ok', nil, nil, SUCCESSFUL_RESPONSE_CODE)
              else
                generate_response('fail', nil, 'FILE DOES NOT EXIST ON SERVER', SERVER_ERROR_CODE)
              end
            end
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# DeleteFile
      app.delete URL + '/accounts/:token/files/:file_id' do
        content_type :json
        token = params[:token]
        file_id = validate_integer(params[:file_id])
        if file_id.nil?
          return generate_response('fail', nil, 'WRONG FILE ID', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            if account[:type] == 'admin'
              stored_file = StoredFile.get_with_author_by_id(file_id)
              if stored_file.nil?
                return generate_response('fail', nil, 'FILE DOES NOT EXIST', CLIENT_ERROR_CODE)
              end
              StoredFile.delete_by_id(file_id)
              file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + file_id.to_s + stored_file[:extension]
              if File.exists?(file_url)
                File.delete(file_url)
              end
              generate_response('ok', {:description => 'FILE WAS DELETED'}, nil, SUCCESSFUL_RESPONSE_CODE)
            else
              stored_file = StoredFile.get_with_author_by_id(file_id)
              if stored_file.nil?
                return generate_response('fail', nil, 'FILE DOES NOT EXIST', CLIENT_ERROR_CODE)
              end
              unless stored_file[:account_id] == account[:id]
                return generate_response('fail', nil, 'USER DOES NOT HAVE ACCESS TO THE FILE', CLIENT_ERROR_CODE)
              end
              StoredFile.delete_by_id(file_id)
              file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + file_id.to_s + stored_file[:extension]
              if File.exists?(file_url)
                File.delete(file_url)
              end
              generate_response('ok', {:description => 'FILE WAS DELETED'}, nil, SUCCESSFUL_RESPONSE_CODE)
            end
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

    end
  end
end