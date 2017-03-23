module ValidationHelpers
  def validate_input
    begin
      input = JSON.parse(request.env["rack.input"].read, symbolize_names: true)
      if input.nil?
        return {status: 'fail', result: 'INPUT HAS TO BE JSON'}
      end
    rescue
      return {status: 'fail', result: 'INPUT HAS TO BE JSON'}
    end
    {status: 'ok', result: input}
  end

  def get_username(user_id, token)
    bio = get_bio_from_accounts(user_id, token)
    puts(bio)
    if bio[:status] == 'ok'
      return bio[:result][:username]
    else
      return nil
    end
  end

  def get_bio_from_accounts(user_id, token)
    response = HTTParty.get(ACCOUNTS_URL + token + "/getBio?id=#{user_id}")
    JSON.parse(response.body, symbolize_names: true)
  end

  def prepare_account(account, token)
    unless account[:owner].nil?
      owner = account[:owner]
      account[:owner] = Hash.new
      account[:owner][:id] = owner
      account[:owner][:username] = get_username(owner, token)
    end
  end

  def prepare_application(application, token)
    unless application[:author].nil?
      author = application[:author]
      application[:author] = Hash.new
      application[:author][:id] = author
     application[:author][:username] = get_username(author, token)
    end
    unless application[:work].nil?
      application[:work].each do |work|
        actor = work[:actor]
        work[:actor] = Hash.new
        work[:actor][:id] = actor
       work[:actor][:username] = get_username(actor, token)
      end
    end
  end

  def prepare_order(order, token)
    unless order[:author].nil?
      author = order[:author]
      order[:author] = Hash.new
      order[:author][:id] = author
      order[:author][:username] = get_username(author, token)
    end
    unless order[:contributors].nil?
      order[:contributors].each do |contributor|
        contributor[:username] = get_username(contributor[:id], token)
      end
    end
  end

  def validate_order(order, author_id)
    unless order.is_a?(Hash)
      return {status: 'fail', description: 'Order has to be an object'}
    end
    if order[:is_joint_purchase].nil? || order[:items].nil?
      return {status: 'fail', description: 'Items and is_joint_purchase can not be null'}
    end
    if !order[:items].is_a?(Array) || order[:items].size == 0
      return {status: 'fail', description: 'Items has to be non empty array'}
    end
    if order[:is_joint_purchase] == 'true' || order[:is_joint_purchase] == true
      order[:is_joint_purchase] = true
    elsif order[:is_joint_purchase] == 'false' || order[:is_joint_purchase] == false
      order[:is_joint_purchase] = false
    else
      return {status: 'fail', description: 'Wrong is_joint_purchase'}
    end
    if order[:is_joint_purchase]
      if order[:items].size != 1
        return {status: 'fail', description: 'Has to be only one item in this type of order'}
      end
      if order[:contributors].nil? || !order[:contributors].is_a?(Array) || order[:contributors].size < 2
        return {status: 'fail', description: 'Contributors has to be array with at least 2 users'}
      end
      item_id = validate_integer(order[:items][0][:id])
      item_amount = validate_integer(order[:items][0][:amount])
      if item_id.nil? || item_amount.nil?
        return {status: 'fail', description: 'Wrong in item'}
      end
      item = ShopItem.get_by_id(item_id)
      if item.nil?
        return {status: 'fail', description: 'Item does not exist'}
      end
      unless item[:possible_joint_purchase]
        return {status: 'fail', description: 'Joint purchase is not possible'}
      end
      if item[:quantity] < item_amount
        return {status: 'fail', description: 'Too big amount'}
      end
      if item[:max_buyers] < order[:contributors].size
        return {status: 'fail', description: 'Too much contributors'}
      end
      order[:items][0][:id] = item_id
      order[:items][0][:amount] = item_amount
      total_points = 0
      author_found = false
      order[:contributors].each do |contributor|
        unless contributor[:id].is_a?(String)
          return {status: 'fail', description: 'contributor id has to be a string'}
        end
        if contributor[:id].length < 24 || contributor[:id].length > 128
          return {status: 'fail', description: 'ACTOR\'S ID LENGTH HAS TO BE BETWEEN 24 and 128'}
        end
        contributor[:points_amount] = validate_integer(contributor[:points_amount])
        if contributor[:points_amount].nil? || contributor[:points_amount] <= 0
          return {status: 'fail', description: 'Wrong contributor points amount'}
        end
        account = Account.get_by_owner(contributor[:id])
        if account.nil?
          return {status: 'fail', description: 'Contributor does not exist'}
        end
        contributor[:id] = account[:id]
        if account[:type] == 'admin'
          return {status: 'fail', description: 'Admin can not buy items'}
        end
        if account[:id] == author_id
          author_found = true
        end
        if account[:points_amount] < contributor[:points_amount]
          return {status: 'fail', description: 'Contributor does not have enough points'}
        end
        total_points += contributor[:points_amount]
      end
      unless author_found
        return {status: 'fail', description: 'Author does not found among the contributors'}
      end
      if total_points != item[:price]
        return {status: 'fail', description: 'Total points do not equal to price of item'}
      end
      order[:total_price] = total_points
    else
      account = Account.get_by_id(author_id)
      if account[:type] == 'admin'
        return {status: 'fail', description: 'Admin can not buy items'}
      end
      total_price = 0
      order[:items].each do |item|
        item[:id] = validate_integer(item[:id])
        item[:amount] = validate_integer(item[:amount])
        if item[:id].nil?
          return {status: 'fail', description: 'Wrong item id'}
        end
        if item[:amount].nil?
          return {status: 'fail', description: 'Wrong item amount'}
        end
        stored_item = ShopItem.get_by_id(item[:id])
        if stored_item.nil?
          return {status: 'fail', description: 'Item does not exist'}
        end
        if stored_item[:quantity] < item[:amount]
          return {status: 'fail', description: 'Too big amount'}
        end
        total_price += stored_item[:price] * item[:amount]
        if account[:points_amount] < total_price
          return {status: 'fail', description: 'User does not have enough points'}
        end
      end
      order[:total_price] = total_price
    end
    {status: 'ok'}
  end

  def validate_integer(integer)
    begin
      integer = Integer(integer)
      integer
    rescue ArgumentError, TypeError
      nil
    end
  end

  def validate_skip(skip)
    begin
      skip = Integer(skip)
    rescue ArgumentError, TypeError
      skip = 0
    end
    if skip < 0
      skip = 0
    end
    skip
  end

  def validate_limit(limit)
    begin
      limit = Integer(limit)
    rescue ArgumentError, TypeError
      limit = DEFAULT_LIMIT
    end
    if limit < 0
      limit = 0
    end
    limit
  end

  def generate_response(status, result, error, status_code)
    status status_code
    resp = Hash.new
    resp[:status] = status
    if status == 'ok'
      resp[:result] = result
    else
      resp[:error] = error
    end
    resp.to_json
  end

  def is_uis_user_exists(token, id)
    resp = JSON.parse(HTTParty.get(ACCOUNTS_URL + token + '/exists?id=' + id).body, symbolize_names: true)
    if resp[:status] == 'ok' && resp[:result]
      return true
    end
    false
  end

  # CheckToken
  def is_token_valid(token)
    if ENV['dev']
      resp = Hash.new
      if token == 'test'
        resp[:status] = 'ok'
        resp[:result] = Hash.new
        resp[:result][:id] = '1'
        resp[:result][:role] = 'student'
      elsif token == 'admin'
        resp[:status] = 'ok'
        resp[:result] = Hash.new
        resp[:result][:id] = '2'
        resp[:result][:role] = 'moderator'
      elsif token == 'student'
        resp[:status] = 'ok'
        resp[:result] = Hash.new
        resp[:result][:id] = '3'
        resp[:result][:role] = 'student'
      elsif token == 'L1mMAJe3Ssnp6D89n8C7e88uOkVuPdgt'
        resp[:status] = 'ok'
        resp[:result] = Hash.new
        resp[:result][:id] = '57c197fc636b0300057ddad2'
        resp[:result][:role] = 'admin'
      else
        resp[:status] = 'error'
      end
      return resp
    end
    resp = HTTParty.get(ACCOUNTS_URL + token)
    JSON.parse(resp.body, symbolize_names: true)
  end

  def validate_item(item)
    unless item.is_a?(Hash)
      return {status: 'fail', description: 'ITEM HAS TO BE AN OBJECT'}
    end
    if item[:title].nil? || !item.is_a?(String)
      return {status: 'fail', description: 'TITLE HAS TO BE A STRING'}
    end
    if item[:options].nil? || !item[:options].is_a?(Array) || item[:options].length > 3
      return {status: 'fail', description: 'OPTIONS HAS TO BE AN ARRAY WITH AT MOST 3 ITEMS'}
    end
    item[:options].each do |option, value|
      unless option.nil?
        if value.nil?
          return {status: 'fail', desciption: 'ERROR IN OPTIONS'}
        end
      end
    end
    item[:quantity] = validate_integer(item[:quantity])
    if item[:quantity].nil? || item[:quantity] <= 0
      return {status: 'fail', description: 'QUANTITY HAS TO BE A POSITIVE INTEGER'}
    end
    item[:price] = validate_integer(item[:price])
    if item[:price].nil? || item[:price] <= 0
      return {status: 'fail', description: 'PRICE HAS TO BE A POSITIVE INTEGER'}
    end
    item[:category_id] = validate_integer(item[:category_id])
    if item[:category_id].nil? || item[:category_id] <= 0
      return {status: 'fail', description: 'WRONG CATEGORY ID'}
    end
    category = ItemCategory.get_by_id(item[:category_id])
    if category.nil?
      return {status: 'fail', description: 'CATEGORY DOES NOT EXIST'}
    end
    if item[:possible_joint_purchase] != 'true' && item[:possible_joint_purchase] != 'false' && item[:possible_joint_purchase] != true && item[:possible_joint_purchase] != false
      return {status: 'fail', description: 'WRONG POSSIBLE JOINT PURCHASE'}
    end
    if item[:possible_joint_purchase] == 'true'
      item[:possible_joint_purchase] = true
    elsif item[:possible_joint_purchase] == 'false'
      item[:possible_joint_purchase] = false
    end
    if item[:possible_joint_purchase]
      item[:max_buyers] = validate_integer(item[:max_buyers])
      if item[:max_buyers].nil? || item[:max_buyers] < 2
        return {status: 'fail', description: 'MAX BUYERS HAS TO BE MORE THAN 1 IF POSSIBLE JOINT PURCHASE IS TRUE'}
      end
    else
      unless item[:max_buyers].nil?
        return {status: 'fail', description: 'MAX BUYERS HAS TO BE NULL IF POSSIBLE JOINT PURCHASE IS FALSE'}
      end
    end
    {status: 'ok'}
  end

  def validate_activity(activity)
    unless activity.is_a?(Hash)
      return {status: 'fail', description: 'ACTIVITY HAS TO BE AN OBJECT'}
    end
    if activity[:type].nil? || (activity[:type] != 'hourly' && activity[:type] != 'quantity' && activity[:type] != 'permanent')
      return {status: 'fail', description: 'WRONG TYPE'}
    end
    if activity[:title].nil? || !activity[:title].is_a?(String)
      return {status: 'fail', description: 'WRONG TITLE'}
    end
    if !activity[:comment].nil? && !activity[:comment].is_a?(String)
      return {status: 'fail', description: 'COMMENT HAS TO BE NULL OR A STRING'}
    end
    if !activity[:for_approval].nil? && !activity[:for_approval].is_a?(String)
      return {status: 'fail', description: 'FOR APPROVAL HAS TO BE NULL OR A STRING'}
    end
    activity[:price] = validate_integer(activity[:price])
    if activity[:price].nil? or activity[:price] <= 0
      return {status: 'fail', description: 'PRICE HAS TO BE A POSITIVE INTEGER'}
    end
    activity[:category_id] = validate_integer(activity[:category_id])
    if activity[:category_id].nil? or activity[:category_id] <= 0
      return {status: 'fail', description: 'CATEGORY ID HAS TO BE A POSITIVE INTEGER'}
    end
    unless Category.exists?(activity[:category_id])
      return {status: 'fail', description: 'CATEGORY DOES NOT EXIST'}
    end
    {status: 'ok'}
  end

  def validate_application(application, token, author_id)
    unless application.is_a?(Hash)
      return {status: 'fail', description: 'APPLICATION HAS TO BE AN OBJECT'}
    end
    if application[:type].nil? || (application[:type] != 'personal' && application[:type] != 'group')
      return {status: 'fail', description: 'WRONG TYPE'}
    end
    if application[:work].nil? || !application[:work].is_a?(Array)
      return {status: 'fail', description: 'WORK HAS TO BE AN ARRAY'}
    end
    if application[:work].size == 0
      return {status: 'fail', description: 'WORK CAN NOT BE EMPTY'}
    end
    if application[:type] == 'personal' && application[:work].size != 1
      return {status: 'fail', description: 'PERSONAL APPLICATION HAS TO CONTAIN ONLY ONE WORK'}
    end
    exists_actors = Array.new
    application[:work].each do |work|
      if work[:actor].nil? || work[:activity_id].nil?
        return {status: 'fail', description: 'ACTOR AND ACTIVITY_ID CAN NOT TO BE NULL'}
      end
      unless work[:actor].is_a?(String)
        return {status: 'fail', description: 'actor has to be a string'}
      end
      if work[:actor].length < 24 || work[:actor].length > 128
        return {status: 'fail', description: 'ACTOR\'S ID LENGTH HAS TO BE BETWEEN 24 and 128'}
      end
      if exists_actors.include?(work[:actor])
        return {status: 'fail', description: 'AN USER CAN BE PRESENT ONLY ONCE IN THE APPLICATION'}
      else
        exists_actors.push(work[:actor])
      end
      work[:activity_id] = validate_integer(work[:activity_id])
      if work[:activity_id].nil?
        return {status: 'fail', description: 'WRONG ACTIVITY ID'}
      end
      activity = Activity.get_by_id(work[:activity_id])
      if activity.nil?
        return {status: 'fail', description: 'ACTIVITY DOES NOT EXIST'}
      end
      if (activity[:type] == 'permanent' && !work[:amount].nil?) ||
          ((activity[:type] == 'hourly' || activity[:type] == 'quantity') && (validate_integer(work[:amount]).nil? || validate_integer(work[:amount]) <= 0))
        return {status: 'fail', description: 'WRONG AMOUNT'}
      end
      account = Account.get_by_owner(work[:actor])
      if account.nil?
        if is_uis_user_exists(token, work[:actor])
          account = Account.create(work[:actor], 'student')
        else
          return {status: 'fail', description: 'ACTOR DOES NOT EXIST IN UIS'}
        end
      end
      if account[:type] == 'admin'
        return {status: 'fail', description: 'ADMIN CAN\'T BE AN ACTOR'}
      end
      if application[:type] == 'personal' && (account[:id] != author_id || account[:type] == 'admin')
        return {status: 'fail', description: 'IN PERSONAL APPLICATION AUTHOR HAS TO BE THE ACTOR'}
      end
      work[:actor] = account[:id]
    end

    if application[:files].nil? || !application[:files].is_a?(Array)
      return {status: 'fail', description: 'FILES HAS TO BE AN ARRAY'}
    end
    application[:files].each do |file_id|
      file_id = validate_integer(file_id)
      if file_id.nil?
        return {status: 'fail', description: 'WRONG FILE ID'}
      end
      file = StoredFile.get_by_id(file_id)
      if file.nil?
        return {status: 'fail', description: 'FILE DOES NOT EXIST'}
      end
    end
    {status: 'ok'}
  end

  def is_enough_points_in_transactions(transactions, amount)
    points = 0
    transactions.each do |transaction|
      puts transaction
      points += transaction[:amount_to_spend]
      if points >= amount
        return true
      end
    end
    false
  end

  def update_points_in_transactions(transactions, points_amount)
    amount = points_amount
    transactions.each do |transaction|
      if transaction[:amount_to_spend] <= amount
        amount -= transaction[:amount_to_spend]
        Transaction.update_amount_and_status(transaction[:id], 0, 'spent')
      else
        amount_to_update = transaction[:amount_to_spend] - amount
        amount = 0
        Transaction.update_amount_and_status(transaction[:id], amount_to_update, 'active')
      end
      if amount == 0
        break
      end
    end
  end

  def deposit_points(account_id, points_amount)
    account = Account.get_by_id(account_id)
    transaction = Transaction.create(account_id, points_amount)
    if account[:points_amount] < 0
      abs_points_amount = account[:points_amount].abs
      if abs_points_amount < points_amount
        Transaction.update_amount_and_status(transaction[:id], points_amount - abs_points_amount, 'active')
      else
        Transaction.update_amount_and_status(transaction[:id], 0, 'spent')
      end
    end
    Account.update_points_amount(account[:id], account[:points_amount] + transaction[:amount])
  end

  def withdraw_points(account_id, points_amount)
    account = Account.get_by_id(account_id)
    transactions = Transaction.get_list_active_by_account(account[:id])
    update_points_in_transactions(transactions, points_amount)
    Account.update_points_amount(account[:id], account[:points_amount] - points_amount)
  end
end
helpers ValidationHelpers