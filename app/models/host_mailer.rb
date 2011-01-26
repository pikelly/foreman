class HostMailer < ActionMailer::Base
  # sends out a summary email of hosts and their metrics (e.g. how many changes failures etc).
  def summary(options = {})
    # currently we send to all registered users or to the administrator (if LDAP is disabled).
    # TODO add support to host / group based emails.

    check_foreman_url

    # options our host list if required
    filter = []

    if options[:env]
      hosts = envhosts = options[:env].hosts
      raise "unable to find any hosts for puppet environment=#{env}" if envhosts.size == 0
      filter << "Environment=#{options[:env].name}"
    end
    name,value = options[:factname],options[:factvalue]
    if name and value
      facthosts = Host.with_fact(name,value)
      raise "unable to find any hosts with the fact name=#{name} and value=#{value}" if facthosts.empty?
      filter << "Fact #{name}=#{value}"
      # if environment and facts are defined together, we use a merge of both
      hosts = envhosts.empty? ? facthosts : envhosts & facthosts
    end

    if hosts.empty?
      # print out an error if we couldn't find any hosts that match our request
      raise "unable to find any hosts that match your request" if options[:env] or options[:factname]
      # we didnt define a filter, use all hosts instead
      hosts=Host
    end
    email = options[:email] || SETTINGS[:administrator] || User.all(:select => :mail).map(&:mail)
    raise "unable to find recipients" if email.empty?
    recipients email
    default_headers

    subject "Summary Puppet report from Foreman"
    time = options[:time] || 1.day.ago
    body[:hosts] = Report.summarise(time, hosts.all).sort
    body[:timerange] = time
    body[:out_of_sync] = hosts.out_of_sync
    body[:disabled] = hosts.alerts_disabled
    body[:filter] = filter
  end

  def error_state(report)
    host = report.host
    email_to_owners host
    default_headers

    subject "Puppet error on #{host.to_label}"
    body[:report] = report
    body[:host] = host
  end

  def mismatched_facts host, mismatched
    check_foreman_url
    email_to_owners host
    default_headers

    subject "Inconsistent facts for #{host.name}"
    body :facts => mismatched, :host => host
  end

  private

  def default_headers
    from         "Foreman-noreply@" + Facter.domain
    sent_on      Time.now
    content_type "text/html"
  end

  def email_to_owners host
    email = host.owner.recipients if SETTINGS[:login] and not host.owner.nil?
    email = SETTINGS[:administrator] if email.empty?
    raise "unable to find recipients" if email.empty?
    recipients email
  end

  def check_foreman_url
    if (body[:url] = SETTINGS[:foreman_url]).empty?
      raise ":foreman_url: entry in Foreman configuration file, see http://theforeman.org/projects/foreman/wiki/Mail_Notifications"
    end
  end
end
