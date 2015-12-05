# encoding: utf-8
#
# This file is a part of Redmine Finance (redmine_finance) plugin,
# simple accounting plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_finance is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_finance is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_finance.  If not, see <http://www.gnu.org/licenses/>.

module OperationsHelper
  def operation_categories_for_select(selected = nil)
    operation_categories = OperationCategory.order("#{OperationCategory.table_name}.is_income DESC").order(:position)
    return "" unless operation_categories.any?
    previous_group = operation_categories.first.is_income?
    s = "<optgroup label=\"#{ERB::Util.html_escape(operation_categories.first.is_income? ? l(:label_operation_income) : l(:label_operation_expense))}\">".html_safe
    operation_categories.each do |category|
      if category.is_income? != previous_group
        reset_cycle
        s << '</optgroup>'.html_safe
        s << "<optgroup label=\"#{ERB::Util.html_escape(category.is_income? ? l(:label_operation_income) : l(:label_operation_expense))}\">".html_safe
        previous_group = category.is_income?
      end
      s << %Q(<option #{'selected="selected"' if category.id == selected.to_i} value="#{ERB::Util.html_escape(category.id)}">#{ERB::Util.html_escape(category.name)}</option>).html_safe
    end
    s << '</optgroup>'
    s.html_safe
  end

  def account_tag(account, options={})
    link_to account.name, account_path(account)
  end

  def opeation_tag(operation, options={})
    link_to operation.to_s, account_path(account)
  end

  def operation_list_styles_for_select
    list_styles = [[l(:label_crm_list_list), "list"]]
  end

  def operations_list_style
    list_styles = operation_list_styles_for_select.map(&:last)
    if params[:operations_list_style].blank?
      list_style = list_styles.include?(session[:operations_list_style]) ? session[:operations_list_style] : list_styles.first
    else
      list_style = list_styles.include?(params[:operations_list_style]) ? params[:operations_list_style] : list_styles.first
    end
    session[:operations_list_style] = list_style
  end

  def operations_contacts_for_select(project)
    scope = Contact.where({})
    scope = scope.joins(:projects).uniq.where(Contact.visible_condition(User.current))
    scope = scope.joins(:operations => :account)
    scope = scope.where(:accounts => {:project_id => project}) if project
    scope.limit(500).map{|c| [c.name, c.id.to_s]}
  end

  def account_current_balance(previous_balance, operation)
    return previous_balance if RedmineFinance.operations_approval? && !operation.is_approved?
    previous_balance - (operation.is_income? ? operation.amount : -operation.amount)
  end

  def disapproved_operations_url(is_income, options={})
    {:controller => 'operations',
     :action => 'index',
     :set_filter => 1,
     :project_id => @project,
     :fields => [:is_approved, :operation_type],
     :values => {:is_approved => ["0"], :operation_type => [is_income ? "1" : "0"]},
     :operators => {:is_approved => '=', :operation_type => '='}}.merge(options)
  end

  def accounts_for_select(project)
    scope = project ? project.accounts : Account.where({})
    scope.all.map{|a| ["#{a.name} (#{a.currency})", a.id.to_s]}
  end

  def operations_balance_to_currency(income_sum, expense_sum)
    currencies = income_sum.map{|a| a[0]} | expense_sum.map{|a| a[0]}
    currencies.map{|a| price_to_currency(income_sum[a].to_f - expense_sum[a].to_f, a)}.join('<br/>').html_safe
    # operations_balance.map{|c| c[0][1].to_i - c[1][1].to_f}
  end

  def operations_to_csv(operations)
    decimal_separator = l(:general_csv_decimal_separator)
    encoding = l(:general_csv_encoding)
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#",
                  'Operation date',
                  'Income',
                  'Expense',
                  'Operation type',
                  'Account',
                  'Description',
                  'Contact',
                  'Created',
                  'Updated'
                  ]
      custom_fields = OperationCustomField.all
      custom_fields.each {|f| headers << f.name}
      # Description in the last column
      csv << headers.collect {|c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) }
      # csv lines
      operations.each do |operation|
        fields = [operation.id,
                  format_date(operation.operation_date),
                  operation.is_income? ? operation.amount : "",
                  operation.is_income? ? "" :  operation.amount,
                  operation.category_name,
                  operation.account.name,
                  operation.description,
                  !operation.contact.blank? ? "##{operation.contact.id}: #{operation.contact.name}" : '',
                  format_date(operation.created_at),
                  format_date(operation.updated_at)
                  ]
        custom_fields.each {|f| fields << RedmineContacts::CSVUtils.csv_custom_value(operation.custom_value_for(f)) }
        csv << fields.collect {|c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) }
      end
    end
    export
  end

end
