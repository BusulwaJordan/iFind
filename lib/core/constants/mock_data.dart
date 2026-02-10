import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/business/domain/entities/business.dart';

class MockData {
  static final User currentUser = User(
    id: 'mock_user_123',
    email: 'user@ifind.com',
    fullName: 'Alex Innovation',
    role: UserRole.businessOwner,
    phone: '+256 700 000000',
    avatarUrl: 'https://i.pravatar.cc/300',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final List<Business> businesses = [
    Business(
      id: 'bus_1',
      ownerId: 'owner_1',
      name: 'Tech Haven Arcade',
      description: 'The ultimate gaming and VR experience in Kampala. Featuring latest consoles and high-end PCs.',
      category: BusinessCategory.arcade,
      address: 'Plot 4, Kampala Road',
      latitude: 0.3476,
      longitude: 32.5825,
      rating: 4.8,
      reviewCount: 124,
      coverImageUrl: 'https://images.unsplash.com/photo-1538481199705-c710c4e965fc?auto=format&fit=crop&q=80&w=1000',
      isVerified: true,
      createdAt: DateTime.now(),
    ),
    Business(
      id: 'bus_2',
      ownerId: 'owner_2',
      name: 'Urban Eats & Co',
      description: 'Fusion cuisine tailored for the modern palate. Best coffee in town.',
      category: BusinessCategory.food,
      address: 'Acacia Mall, Kisementi',
      latitude: 0.3500,
      longitude: 32.5900,
      rating: 4.5,
      reviewCount: 89,
      coverImageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=1000',
      isVerified: true,
      createdAt: DateTime.now(),
    ),
    Business(
      id: 'bus_3',
      ownerId: 'owner_3',
      name: 'Style Studio',
      description: 'Premium fashion for men and women. Custom tailoring available.',
      category: BusinessCategory.retail,
      address: 'Village Mall, Bugolobi',
      latitude: 0.3300,
      longitude: 32.6000,
      rating: 4.2,
      reviewCount: 45,
      coverImageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&q=80&w=1000',
      isVerified: false,
      createdAt: DateTime.now(),
    ),
  ];
}
