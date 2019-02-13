require 'selenium-webdriver'

        class FillApplication
          attr_accessor :data

          def initialize(params)
            @data = params
          end

          def send_request
            return error_response  if errors.any?
            response
          end

          private

          def error_response
            {errors: errors}
          end

          def errors
            FillApplicationValidator.validate(data).errors
          end

          def response
            submit_data_to_ocbc
          end

          def submit_data_to_ocbc
            setup_driver
            pick_the_right_card('365')
            fill_in_personal_details
            fill_in_contact_details
            fill_in_employment_details
            fill_in_income_details
            fill_in_card_options
            fill_in_captcha
            submit_the_form
            parse_response
          end


          private


          def setup_driver
            options = Selenium::WebDriver::Chrome::Options.new
            # options.add_argument('--headless') 
            # options.add_argument('--no-sandbox')
            # options.add_argument('--disable-gpu')
            # options.add_argument('--disable-popup-blocking')
            # options.add_argument('--window-size=1366,768')
            options.add_preference(:download, directory_upgrade: true,
                                            prompt_for_download: false,
                                            default_directory: 'tmp')

            options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })


            # two_second_wait = Selenium::WebDriver::Wait.new(:timeout => 2)
            # five_second_wait = Selenium::WebDriver::Wait.new(:timeout => 5)
            # success_wait = Selenium::WebDriver::Wait.new(:timeout => 100)

            # begin
            #   driver.get(Configuration.config.ocbc_base_url)
            #   driver.find_element(css: '[data-card="365"]').click
            #   driver.switch_to.window( driver.window_handles.last)
            #   sleep(2)
            #   driver.find_element(:css, '#App_CustList_0__IsExCust[value="N"]').click
            #   driver.find_element(:id, 'btnApply').click
            #   sleep(2)

            #   #Personal details
            #   driver.find_element(:id, 'App_CustList_0__SalCd').find_element(:css, "option[value=\"#{data[:title]}\"]").click
            # rescue
            #   puts 'retrying'
            #   retry
            # end
            @driver = Selenium::WebDriver.for(:chrome, options: options)

            # bridge = @driver.send(:bridge)
            # path = '/session/:session_id/chromium/send_command'
            # path[':session_id'] = bridge.session_id
            # bridge.http.call(:post, path, cmd: 'Page.setDownloadBehavior',
            #                             params: {
            #                               behavior: 'allow',
            #                               downloadPath: 'tmp'
            #                             })

            puts 'Done setting up the driver'
          end

          def pick_the_right_card(card_name)
            @driver.get(Configuration.config.ocbc_base_url)
            @driver.find_element(css: "[data-card=\"#{card_name}\"]").click
            @driver.switch_to.window( @driver.window_handles.last)
            sleep(2)
            @driver.find_element(:css, '#App_CustList_0__IsExCust[value="N"]').click
            @driver.find_element(:id, 'btnApply').click
            sleep(2)
            puts 'Done picking the card'
          end

          def fill_in_personal_details
            @driver.find_element(:id, 'App_CustList_0__SalCd').find_element(:css, "option[value=\"#{data[:title]}\"]").click
            @driver.find_element(:id, 'App_CustList_0__Nm').send_keys(data[:name])
            @driver.find_element(:id, 'App_CustList_0__FacRelShip_0__NameOnCard').send_keys(data[:nameOnCard])
            @driver.find_element(:id, 'App_CustList_0__DOBDate').find_element(:css, "option[value=\"#{data[:dobDate]}\"]").click
            @driver.find_element(:id, 'App_CustList_0__DOBMonth').find_element(:css, "option[value=\"#{data[:dobMonth]}\"]").click
            @driver.find_element(:id, 'App_CustList_0__DOBYear').clear()
            @driver.find_element(:id, 'App_CustList_0__DOBYear').send_keys(data[:dobYear])
            @driver.find_element(:id, 'App_CustList_0__CountryOfBirthCd').find_element(:css, "option[value=\"#{data[:country]}\"]").click
            if(data[:isSingaporean] == 'Singaporean')
              @driver.find_element(:css, '#App_CustList_0__AreYouSingaporean[value="Y"]').click
              @driver.find_element(:id, 'App_CustList_0__NRIC').send_keys(data[:nric])
            else
              @driver.find_element(:css, '#App_CustList_0__AreYouSingaporean[value="N"]').click
            end
            @driver.find_element(:id, 'App_CustList_0__NoOfDep').find_element(:css, "option[value=\"#{data[:numberOfDependants]}\"]").click
            @driver.find_element(:id, 'App_CustList_0__EdLevelCd').find_element(:css, "option[value=\"#{data[:educationLevel]}\"]").click
            @driver.find_element(:id, 'App_CustList_0__MotherMaiden').send_keys(data[:motherMaidenName])
            puts 'Done filling in personal details'
          end

          def fill_in_contact_details
            @driver.find_element(:id, 'contact-details').click
            @driver.find_element(:id, 'App_CustList_0__MobileNo').send_keys(data[:homeNumber])
            @driver.find_element(:id, 'App_CustList_0__HomeOfficeNo').send_keys(data[:mobileNumber])
            @driver.find_element(:id, 'App_CustList_0__Email').clear()
            @driver.find_element(:id, 'App_CustList_0__Email').send_keys(data[:email])
            @driver.find_element(:id, 'App_CustList_0__CustAdd_0__ResidentStatusCd').find_element(:css, "option[value=\"#{data[:residentialStatus]}\"]").click
            @driver.find_element(:id, 'App_CustList_0__CustAdd_0__YearsInResidence').find_element(:css, "option[value=\"#{data[:yearsInResidence]}\"]").click
            @driver.find_element(:id, 'App_CustList_0__CustAdd_0__PostalCode').send_keys(data[:homePostalCode])
            @driver.find_element(:id, 'App_CustList_0__CustAdd_0__BlockNo').send_keys(data[:homeBlockNumber])
            @driver.find_element(:id, 'App_CustList_0__CustAdd_0__FloorNo').send_keys(get_floor_number(data[:homeUnitNumber]))
            @driver.find_element(:id, 'App_CustList_0__CustAdd_0__UnitNo').send_keys(get_unit_number(data[:homeUnitNumber]))
            @driver.find_element(:id, 'App_CustList_0__CustAdd_0__StreetName').send_keys(data[:homeStreet])
            if(data[:isPreferredAddressHome])
              @driver.find_element(:css, '#App_CustList_0__PrefMailAdd[value="H"]').click
            else
              @driver.find_element(:css, '#App_CustList_0__PrefMailAdd[value="O"]').click
              @driver.find_element(:id, 'App_CustList_0__CustAdd_1__PostalCode').send_keys(data[:officePostalCode])
              @driver.find_element(:id, 'App_CustList_0__CustAdd_1__BlockNo').send_keys(data[:officeBlockNumber])
              @driver.find_element(:id, 'App_CustList_0__CustAdd_1__FloorNo').send_keys(get_floor_number(data[:officeUnitNumber]))
              @driver.find_element(:id, 'App_CustList_0__CustAdd_1__UnitNo').send_keys(get_unit_number(data[:officeUnitNumber]))
              @driver.find_element(:id, 'App_CustList_0__CustAdd_1__StreetName').send_keys(data[:officeStreet])
            end
            @driver.find_element(:id, 'App_CustList_0__IsMrktConsentByPhoneAndSMS').click
            puts 'Done filling in contact details'
          end

          def fill_in_employment_details
            @driver.find_element(:id, 'employer-details').click
            @driver.find_element(:id, 'App_CustList_0__Emp_OccupationCd').find_element(:css, "option[value=\"#{data[:occupation]}\"]").click
            @driver.find_element(:id, 'App_CustList_0__Emp_EmployerNm').send_keys(data[:nameOfEmployer])
            @driver.find_element(:id, 'App_CustList_0__Emp_LenOfSvc').find_element(:css, "option[value=\"#{data[:yearsWithEmployer]}\"]").click
            @driver.find_element(:id, 'App_CustList_0__Emp_BizzTypeCd').find_element(:css, "option[value=\"#{data[:natureOfBusiness]}\"]").click
            @driver.find_element(:id, 'App_CustList_0__Emp_AnnualIncRangeCd').find_element(:css, "option[value=\"#{data[:annualIncome]}\"]").click
            if(data[:isSelfEmployed])
              @driver.find_element(:id, 'App_CustList_0__Emp_IsSelfEmployed').find_element(:css, 'option[value="Y"]').click
            else
              @driver.find_element(:id, 'App_CustList_0__Emp_IsSelfEmployed').find_element(:css, 'option[value="N"]').click
            end
            sleep(2)
            puts 'Done filling in employment details'
          end

          def fill_in_income_details
            if(data[:isCreditLimitAccepted])
              @driver.find_element(:css, '#creditLimitByBankButton a').click
            else
              @driver.find_element(:id, 'App_UserPreferredCreditLimitValue').send_keys(data[:preferredCreditCardLimit])
            end
            @driver.find_element(:id, 'skipcpf').click
            sleep(2)
            puts 'Done filling in income details'
          end

          def fill_in_card_options
            @driver.find_element(:id, 'card-options').click
            @driver.find_element(:id, 'App_FacList_0__ApplyeStt').click if data{:isHardCopyPreferred}
            @driver.find_element(:id, 'App_FacList_0__ApplyCW').click
          end

          def fill_in_captcha
            retry_captcha = 0
            src = @driver.find_element(:id, 'regCaptcha').attribute('src')
            @driver.execute_script('window.open()')
            @driver.switch_to.window(@driver.window_handles.last)
            @driver.get(src)
            sleep(2)

            client = DeathByCaptcha.new(ENV['DEATH_BY_CAPTCHA_UNAME'], ENV['DEATH_BY_CAPTCHA_PWD'], :http)
            begin
              captcha = client.decode!(path: 'tmp/a.jpg')
            rescue Exception => e
              retry_captcha += 1
              puts e.message
              puts retry_captcha
              retry if retry_captcha < 3
            end
            @driver.close
            @driver.switch_to.window(@driver.window_handles.last)
            File.delete('tmp/a.jpg') if File.exist?('tmp/a.jpg')
            @driver.find_element(:id, 'Captcha').send_keys(captcha.text)
          end

          def submit_the_form
            @driver.find_element(:id, 'btnToReview').click
            sleep(5)

            #Summary
            @driver.find_element(:id, 'AgreedDeclaration').click
            @driver.find_element(:id, 'btnSubmitApplication').click
          end

          def parse_response
            #Check-Success
            success_wait = Selenium::WebDriver::Wait.new(:timeout => 100)
            success_wait.until { @driver.find_element(:id, 'frm-apply-credit-card').text.strip.include? 'Thank you, we have received your application.' }
            if @driver.find_element(:id, 'frm-apply-credit-card').text.strip.include? 'Thank you, we have received your application.'
              puts 'Success'
            else
              puts 'Failed'
            end

            @driver.quit
          end

          def get_floor_number(unit)
            unit.split('-')[0]
          end

          def get_unit_number(unit)
            unit.split('-')[1]
          end

        end
      end
    end
  end
end
