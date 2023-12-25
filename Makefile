include properties.mk

JAVA_OPTIONS = JDK_JAVA_OPTIONS="--add-modules=java.xml.bind"

package:
	@$(JAVA_HOME)/bin/java \
	-Dfile.encoding=UTF-8 \
  	-Dapple.awt.UIElement=true \
	-jar "$(SDK_HOME)/bin/monkeybrains.jar" \
  	-o dist/GRun_Chinese.iq \
	-e \
	-w \
	-y $(PRIVATE_KEY) \
	-r -l 0 \
	-f monkey.jungle
package_i18n:
	@$(JAVA_HOME)/bin/java \
	-Dfile.encoding=UTF-8 \
  	-Dapple.awt.UIElement=true \
	-jar "$(SDK_HOME)/bin/monkeybrains.jar" \
  	-o dist/GRun_i18n.iq \
	-e \
	-w \
	-y $(PRIVATE_KEY) \
	-r -l 0 \
	-f monkey-i18n.jungle

packageall: package_i18n package