include properties.mk

appName = "GRun_i18n"
JAVA_OPTIONS = JDK_JAVA_OPTIONS="--add-modules=java.xml.bind"

package:
	@$(JAVA_HOME)/bin/java \
	-Dfile.encoding=UTF-8 \
  	-Dapple.awt.UIElement=true \
	-jar "$(SDK_HOME)/bin/monkeybrains.jar" \
  	-o dist/$(appName).iq \
	-e \
	-w \
	-y $(PRIVATE_KEY) \
	-r -l 0 \
	-f monkey-i18n.jungle

packageall: package1 package2 package3